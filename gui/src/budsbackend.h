#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QProcess>

class BudsBackend : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool connected READ isConnected NOTIFY statusChanged)
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY statusChanged)
    Q_PROPERTY(QString statusSubtitle READ statusSubtitle NOTIFY statusChanged)
    Q_PROPERTY(QString profileVersion READ profileVersion NOTIFY statusChanged)
    Q_PROPERTY(QString hardwareInfo READ hardwareInfo NOTIFY statusChanged)

    Q_PROPERTY(int leftBattery READ leftBattery NOTIFY batteryChanged)
    Q_PROPERTY(bool leftCharging READ isLeftCharging NOTIFY batteryChanged)
    Q_PROPERTY(int rightBattery READ rightBattery NOTIFY batteryChanged)
    Q_PROPERTY(bool rightCharging READ isRightCharging NOTIFY batteryChanged)
    Q_PROPERTY(int caseBattery READ caseBattery NOTIFY batteryChanged)
    Q_PROPERTY(bool caseCharging READ isCaseCharging NOTIFY batteryChanged)

    Q_PROPERTY(QString ancMode READ ancMode NOTIFY ancChanged)
    Q_PROPERTY(bool gameMode READ isGameMode NOTIFY gameModeChanged)
    Q_PROPERTY(int spatialMode READ spatialMode NOTIFY spatialChanged)
    Q_PROPERTY(int eqPreset READ eqPreset NOTIFY eqChanged)
    Q_PROPERTY(bool inEarDetection READ isInEarDetection NOTIFY inEarChanged)
    Q_PROPERTY(bool dualConnection READ isDualConnection NOTIFY dualConnectionChanged)

public:
    explicit BudsBackend(QObject *parent = nullptr);
    ~BudsBackend() override = default;

    bool isConnected() const { return m_connected; }
    bool isLoading() const { return m_loading; }
    QString deviceName() const { return m_deviceName; }
    QString statusSubtitle() const { return m_statusSubtitle; }
    QString profileVersion() const { return m_profileVersion; }
    QString hardwareInfo() const { return m_hardwareInfo; }

    int leftBattery() const { return m_leftBattery; }
    bool isLeftCharging() const { return m_leftCharging; }
    int rightBattery() const { return m_rightBattery; }
    bool isRightCharging() const { return m_rightCharging; }
    int caseBattery() const { return m_caseBattery; }
    bool isCaseCharging() const { return m_caseCharging; }

    QString ancMode() const { return m_ancMode; }
    bool isGameMode() const { return m_gameMode; }
    int spatialMode() const { return m_spatialMode; }
    int eqPreset() const { return m_eqPreset; }
    bool isInEarDetection() const { return m_inEarDetection; }
    bool isDualConnection() const { return m_dualConnection; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setAncMode(const QString &mode);
    Q_INVOKABLE void setGameMode(bool enabled);
    Q_INVOKABLE void setSpatialMode(int modeIndex);
    Q_INVOKABLE void setEqPreset(int presetIndex);
    Q_INVOKABLE void setInEarDetection(bool enabled);
    Q_INVOKABLE void setDualConnection(bool enabled);
    Q_INVOKABLE void findBuds(const QString &target);

signals:
    void statusChanged();
    void loadingChanged();
    void batteryChanged();
    void ancChanged();
    void gameModeChanged();
    void spatialChanged();
    void eqChanged();
    void inEarChanged();
    void dualConnectionChanged();
    void notifyMessage(const QString &text, bool isError);

private slots:
    void onRefreshTimeout();

private:
    QString findCliBinary() const;
    void executeCommandAsync(const QStringList &args,
                             const std::function<void(bool success, const QString &stdoutStr, const QString &stderrStr)> &callback);

    bool m_connected = false;
    bool m_loading = false;
    QString m_deviceName = "Motorola Moto Buds";
    QString m_statusSubtitle = "Buscando conexión...";
    QString m_profileVersion = "-";
    QString m_hardwareInfo = "-";

    int m_leftBattery = -1;
    bool m_leftCharging = false;
    int m_rightBattery = -1;
    bool m_rightCharging = false;
    int m_caseBattery = -1;
    bool m_caseCharging = false;

    QString m_ancMode = "Off";
    bool m_gameMode = false;
    int m_spatialMode = 0;
    int m_eqPreset = 1;
    bool m_inEarDetection = false;
    bool m_dualConnection = false;

    QTimer m_pollTimer;
    QString m_cliPath;
};
