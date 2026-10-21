#include "budsbackend.h"

#include <QStandardPaths>
#include <QFileInfo>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QThread>
#include <QDebug>

BudsBackend::BudsBackend(QObject *parent)
    : QObject(parent)
{
    m_cliPath = findCliBinary();

    connect(&m_pollTimer, &QTimer::timeout, this, &BudsBackend::onRefreshTimeout);
    m_pollTimer.setInterval(25000); // 25 seconds
    m_pollTimer.start();

    // Trigger initial status check
    QTimer::singleShot(200, this, &BudsBackend::refresh);
}

QString BudsBackend::findCliBinary() const
{
    QString localCargo = QDir::homePath() + "/.cargo/bin/moto-buds";
    if (QFileInfo::exists(localCargo) && QFileInfo(localCargo).isExecutable()) {
        return localCargo;
    }

    QString inPath = QStandardPaths::findExecutable("moto-buds");
    if (!inPath.isEmpty()) {
        return inPath;
    }

    return "/usr/local/bin/moto-buds";
}

void BudsBackend::executeCommandAsync(const QStringList &args,
                                     const std::function<void(bool, const QString &, const QString &)> &callback)
{
    QString program = m_cliPath;
    if (program.isEmpty() || !QFileInfo::exists(program)) {
        program = findCliBinary();
        const_cast<BudsBackend*>(this)->m_cliPath = program;
    }

    QThread *workerThread = QThread::create([program, args, callback]() {
        QProcess proc;
        proc.start(program, args);
        bool finished = proc.waitForFinished(10000);

        bool success = finished && (proc.exitStatus() == QProcess::NormalExit) && (proc.exitCode() == 0);
        QString stdoutStr = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        QString stderrStr = QString::fromUtf8(proc.readAllStandardError()).trimmed();

        if (!finished) {
            proc.kill();
            success = false;
            stderrStr = "Operación cancelada por tiempo de espera";
        }

        if (callback) {
            callback(success, stdoutStr, stderrStr);
        }
    });

    connect(workerThread, &QThread::finished, workerThread, &QObject::deleteLater);
    workerThread->start();
}

void BudsBackend::onRefreshTimeout()
{
    if (!m_loading) {
        refresh();
    }
}

void BudsBackend::refresh()
{
    if (m_loading) return;

    m_loading = true;
    emit loadingChanged();
    m_statusSubtitle = "Consultando dispositivo...";
    emit statusChanged();

    executeCommandAsync({"--json", "status"}, [this](bool success, const QString &stdoutStr, const QString &stderrStr) {
        // Return to main thread via metaObject invocation or event loop
        QMetaObject::invokeMethod(this, [this, success, stdoutStr, stderrStr]() {
            m_loading = false;
            emit loadingChanged();

            if (!success || stdoutStr.isEmpty()) {
                m_connected = false;
                m_statusSubtitle = "Desconectado";
                m_leftBattery = -1;
                m_rightBattery = -1;
                m_caseBattery = -1;
                emit statusChanged();
                emit batteryChanged();
                return;
            }

            QJsonParseError parseErr;
            QJsonDocument doc = QJsonDocument::fromJson(stdoutStr.toUtf8(), &parseErr);
            if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
                m_statusSubtitle = "Error al interpretar datos";
                emit statusChanged();
                return;
            }

            QJsonObject root = doc.object();
            m_connected = true;
            m_deviceName = root.value("name").toString("Motorola Moto Buds");
            m_statusSubtitle = "Conectado (" + m_deviceName + ")";
            m_profileVersion = root.value("profile_version").toString("1.8");
            m_hardwareInfo = root.value("hardware_info").toString("Moto Buds");

            // Battery
            QJsonObject bat = root.value("battery").toObject();
            QJsonObject left = bat.value("left").toObject();
            QJsonObject right = bat.value("right").toObject();
            QJsonObject cObj = bat.value("case").toObject();

            m_leftBattery = left.contains("percentage") ? left.value("percentage").toInt(-1) : -1;
            m_leftCharging = left.value("is_charging").toBool(false);

            m_rightBattery = right.contains("percentage") ? right.value("percentage").toInt(-1) : -1;
            m_rightCharging = right.value("is_charging").toBool(false);

            m_caseBattery = cObj.contains("percentage") ? cObj.value("percentage").toInt(-1) : -1;
            m_caseCharging = cObj.value("is_charging").toBool(false);

            // ANC
            m_ancMode = root.value("anc_mode").toString("Off");

            // Sound
            m_gameMode = root.value("game_mode").toBool(false);
            m_eqPreset = root.value("eq_state").toInt(1);

            // Intelligence
            m_inEarDetection = root.value("in_ear_detection").toBool(false);
            m_dualConnection = root.value("dual_connection").toBool(false);

            emit statusChanged();
            emit batteryChanged();
            emit ancChanged();
            emit gameModeChanged();
            emit eqChanged();
            emit inEarChanged();
            emit dualConnectionChanged();
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::setAncMode(const QString &mode)
{
    QString cliArg = mode.toLower();
    if (cliArg == "noisecancellation" || cliArg == "high") {
        cliArg = "noise-cancelling";
    }

    executeCommandAsync({"anc", cliArg}, [this, mode](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, mode, stderrStr]() {
            if (success) {
                m_ancMode = mode;
                emit ancChanged();
                emit notifyMessage("Modo de cancelación actualizado", false);
            } else {
                if (stderrStr.contains("error code: 2") || stderrStr.contains("error code 2")) {
                    emit notifyMessage("Ponte ambos auriculares en las orejas para activar la cancelación", true);
                } else if (stderrStr.contains("Host is down") || stderrStr.contains("os error 112")) {
                    emit notifyMessage("Auriculares desconectados en Bluetooth", true);
                } else {
                    emit notifyMessage("No se pudo cambiar el modo de ruido", true);
                }
                // Refresh to sync state back
                refresh();
            }
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::setGameMode(bool enabled)
{
    executeCommandAsync({"game-mode", enabled ? "on" : "off"}, [this, enabled](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, enabled, stderrStr]() {
            if (success) {
                m_gameMode = enabled;
                emit gameModeChanged();
                emit notifyMessage(enabled ? "Modo Juego activado" : "Modo Juego desactivado", false);
            } else {
                emit notifyMessage("Error al cambiar Modo Juego", true);
                refresh();
            }
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::setSpatialMode(int modeIndex)
{
    QString arg = (modeIndex == 1) ? "fixed" : (modeIndex == 2) ? "head-tracking" : "off";
    executeCommandAsync({"spatial", arg}, [this, modeIndex](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, modeIndex, stderrStr]() {
            if (success) {
                m_spatialMode = modeIndex;
                emit spatialChanged();
                emit notifyMessage("Audio Espacial actualizado", false);
            } else {
                emit notifyMessage("Error al cambiar Audio Espacial", true);
                refresh();
            }
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::setEqPreset(int presetIndex)
{
    executeCommandAsync({"eq", "--set", QString::number(presetIndex)}, [this, presetIndex](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, presetIndex, stderrStr]() {
            if (success) {
                m_eqPreset = presetIndex;
                emit eqChanged();
                emit notifyMessage("Perfil de ecualización aplicado", false);
            } else {
                emit notifyMessage("Error al aplicar ecualizador", true);
                refresh();
            }
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::setInEarDetection(bool enabled)
{
    executeCommandAsync({"in-ear", enabled ? "on" : "off"}, [this, enabled](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, enabled, stderrStr]() {
            if (success) {
                m_inEarDetection = enabled;
                emit inEarChanged();
                emit notifyMessage(enabled ? "Detección en oreja activada" : "Detección en oreja desactivada", false);
            } else {
                emit notifyMessage("Error al cambiar detección en oreja", true);
                refresh();
            }
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::setDualConnection(bool enabled)
{
    executeCommandAsync({"dual-conn", enabled ? "on" : "off"}, [this, enabled](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, enabled, stderrStr]() {
            if (success) {
                m_dualConnection = enabled;
                emit dualConnectionChanged();
                emit notifyMessage(enabled ? "Conexión Dual activada" : "Conexión Dual desactivada", false);
            } else {
                emit notifyMessage("Error al cambiar Conexión Dual", true);
                refresh();
            }
        }, Qt::QueuedConnection);
    });
}

void BudsBackend::findBuds(const QString &target)
{
    executeCommandAsync({"find", target}, [this, target](bool success, const QString &, const QString &stderrStr) {
        QMetaObject::invokeMethod(this, [this, success, target, stderrStr]() {
            if (success) {
                if (target == "stop") {
                    emit notifyMessage("Alerta sonora detenida", false);
                } else {
                    emit notifyMessage("Emitiendo señal sonora de localización", false);
                }
            } else {
                emit notifyMessage("Error al enviar comando de localización", true);
            }
        }, Qt::QueuedConnection);
    });
}
