#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QIcon>
#include <QDir>
#include <QDebug>

#include "budsbackend.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);
    app.setApplicationName("Moto Buds");
    app.setApplicationDisplayName("Moto Buds");
    app.setOrganizationName("Motorola");
    app.setOrganizationDomain("com.motorola.motobuds");
    app.setWindowIcon(QIcon(":/qt/qml/MotoBuds/assets/icon.png"));

    // Register Material Symbols font
    QString fontPath = ":/qt/qml/MotoBuds/assets/MaterialSymbolsRounded.ttf";
    if (!QDir().exists(fontPath)) {
        fontPath = "/usr/share/fonts/TTF/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf";
    }
    int fontId = QFontDatabase::addApplicationFont(fontPath);
    if (fontId != -1) {
        QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        qDebug() << "Loaded Material Symbols font families:" << families;
    } else {
        qWarning() << "Failed to register Material Symbols font from" << fontPath;
    }

    QQmlApplicationEngine engine;

    BudsBackend backend;
    engine.rootContext()->setContextProperty("backend", &backend);

    const QUrl url(QStringLiteral("qrc:/qt/qml/MotoBuds/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
