import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 460
    height: 760
    minimumWidth: 380
    minimumHeight: 600
    title: "Moto Buds"
    color: "#0d0f13"

    // Toast state
    property string toastText: ""
    property bool toastIsError: false
    property bool toastVisible: false

    Connections {
        target: backend
        function onNotifyMessage(text, isError) {
            window.toastText = text;
            window.toastIsError = isError;
            window.toastVisible = true;
            toastTimer.restart();
        }
    }

    Timer {
        id: toastTimer
        interval: 3500
        onTriggered: window.toastVisible = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. TOP HEADER BAR
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#14171d"
            border.color: "#1f232b"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Moto Buds"
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    Text {
                        text: backend.statusSubtitle
                        color: backend.connected ? "#2ec27e" : "#8c93a0"
                        font.pixelSize: 11
                    }
                }

                // Refresh Button with Material Symbol
                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: refreshArea.containsMouse ? "#252b36" : "#1a1f27"
                    border.color: "#282e3a"
                    border.width: 1

                    MaterialIcon {
                        id: refreshIcon
                        name: "refresh"
                        size: 20
                        iconColor: backend.loading ? "#0082c8" : "#dcdfe4"
                        anchors.centerIn: parent

                        RotationAnimation on rotation {
                            running: backend.loading
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 900
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.refresh()
                    }
                }
            }
        }

        // 2. SCROLLABLE BODY
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight + 32
            clip: true

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: contentCol
                width: Math.min(parent.width - 32, 460)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 16
                spacing: 16

                // A. HERO CARD
                Rectangle {
                    width: parent.width
                    height: heroCol.implicitHeight + 28
                    radius: 16
                    color: "#14171d"
                    border.color: "#212631"
                    border.width: 1

                    Column {
                        id: heroCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Image {
                            source: "qrc:/qt/qml/MotoBuds/assets/case_open_buds.webp"
                            width: 200
                            height: 160
                            fillMode: Image.PreserveAspectFit
                            anchors.horizontalCenter: parent.horizontalCenter
                            smooth: true
                        }

                        Text {
                            text: backend.deviceName
                            color: "#ffffff"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        // Connection Pill
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 24
                            width: connText.implicitWidth + 24
                            radius: 12
                            color: backend.connected ? "#153326" : "#32191c"
                            border.color: backend.connected ? "#2ec27e" : "#e01b24"
                            border.width: 1

                            Text {
                                id: connText
                                anchors.centerIn: parent
                                text: backend.connected ? "Conectado" : "Desconectado"
                                color: backend.connected ? "#2ec27e" : "#e01b24"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        // Battery row (Left, Case, Right)
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            width: parent.width

                            BatteryCard {
                                width: (parent.width - 16) / 3
                                title: "Izquierdo"
                                imageSource: "qrc:/qt/qml/MotoBuds/assets/left.webp"
                                percentage: backend.leftBattery
                                isCharging: backend.leftCharging
                                connected: backend.connected
                            }

                            BatteryCard {
                                width: (parent.width - 16) / 3
                                title: "Estuche"
                                imageSource: "qrc:/qt/qml/MotoBuds/assets/case.webp"
                                percentage: backend.caseBattery
                                isCharging: backend.caseCharging
                                connected: backend.connected
                            }

                            BatteryCard {
                                width: (parent.width - 16) / 3
                                title: "Derecho"
                                imageSource: "qrc:/qt/qml/MotoBuds/assets/right.webp"
                                percentage: backend.rightBattery
                                isCharging: backend.rightCharging
                                connected: backend.connected
                            }
                        }
                    }
                }

                // B. NOISE CANCELLATION CARD
                Card {
                    width: parent.width

                    Row {
                        spacing: 8
                        MaterialIcon {
                            name: "noise_aware"
                            size: 20
                            iconColor: "#0082c8"
                        }
                        Text {
                            text: "Control de Ruido"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "Selecciona el nivel de aislamiento acústico"
                        color: "#7e8694"
                        font.pixelSize: 11
                    }

                    AncSelector {
                        width: parent.width
                        currentMode: backend.ancMode
                        onModeSelected: function(mode) {
                            backend.setAncMode(mode)
                        }
                    }
                }

                // C. SOUND & PERFORMANCE CARD
                Card {
                    width: parent.width

                    Row {
                        spacing: 8
                        MaterialIcon {
                            name: "graphic_eq"
                            size: 20
                            iconColor: "#0082c8"
                        }
                        Text {
                            text: "Sonido y Rendimiento"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    SettingRow {
                        width: parent.width
                        iconName: "sports_esports"
                        title: "Modo Juego"
                        subtitle: "Baja latencia para sincronización en juegos y vídeos"
                        isChecked: backend.gameMode
                        onToggled: function(active) {
                            backend.setGameMode(active)
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#212631"
                    }

                    // Spatial Audio Selector
                    Column {
                        width: parent.width
                        spacing: 6

                        Row {
                            spacing: 12
                            Rectangle {
                                width: 38
                                height: 38
                                radius: 8
                                color: "#232731"
                                MaterialIcon {
                                    name: "surround_sound"
                                    size: 20
                                    anchors.centerIn: parent
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: "Audio Espacial"
                                    color: "#f0f2f5"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "Inmersión acústica envolvente"
                                    color: "#7e8694"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: ["Desactivado", "Fijo", "Seguimiento"]
                                delegate: Rectangle {
                                    width: (parent.width - 12) / 3
                                    height: 34
                                    radius: 6
                                    property bool isSel: backend.spatialMode === index
                                    color: isSel ? "#0082c8" : (spArea.containsMouse ? "#282e3b" : "#1e222b")
                                    border.color: isSel ? "#0095e6" : "#2d323c"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: parent.isSel ? "#ffffff" : "#a0a6b5"
                                        font.pixelSize: 11
                                        font.weight: parent.isSel ? Font.Bold : Font.Normal
                                    }

                                    MouseArea {
                                        id: spArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.setSpatialMode(index)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#212631"
                    }

                    // Equalizer Selector
                    Column {
                        width: parent.width
                        spacing: 6

                        Row {
                            spacing: 12
                            Rectangle {
                                width: 38
                                height: 38
                                radius: 8
                                color: "#232731"
                                MaterialIcon {
                                    name: "equalizer"
                                    size: 20
                                    anchors.centerIn: parent
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: "Ecualizador"
                                    color: "#f0f2f5"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "Perfil de calibración de audio"
                                    color: "#7e8694"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 6

                            Repeater {
                                model: [
                                    { idx: 0, label: "Original" },
                                    { idx: 1, label: "Predeterminado" },
                                    { idx: 2, label: "Realce de Graves" },
                                    { idx: 3, label: "Voces Claras" }
                                ]
                                delegate: Rectangle {
                                    width: (parent.width - 6) / 2
                                    height: 34
                                    radius: 6
                                    property bool isSel: backend.eqPreset === modelData.idx
                                    color: isSel ? "#0082c8" : (eqArea.containsMouse ? "#282e3b" : "#1e222b")
                                    border.color: isSel ? "#0095e6" : "#2d323c"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: parent.isSel ? "#ffffff" : "#a0a6b5"
                                        font.pixelSize: 11
                                        font.weight: parent.isSel ? Font.Bold : Font.Normal
                                    }

                                    MouseArea {
                                        id: eqArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.setEqPreset(modelData.idx)
                                    }
                                }
                            }
                        }
                    }
                }

                // D. INTELLIGENCE CARD
                Card {
                    width: parent.width

                    Row {
                        spacing: 8
                        MaterialIcon {
                            name: "psychology"
                            size: 20
                            iconColor: "#0082c8"
                        }
                        Text {
                            text: "Ajustes Inteligentes"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    SettingRow {
                        width: parent.width
                        iconName: "hearing"
                        title: "Detección en Oreja"
                        subtitle: "Pausa o reanuda al poner o quitar auriculares"
                        isChecked: backend.inEarDetection
                        onToggled: function(active) {
                            backend.setInEarDetection(active)
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#212631"
                    }

                    SettingRow {
                        width: parent.width
                        iconName: "devices"
                        title: "Conexión Dual (Multipoint)"
                        subtitle: "Conexión activa simultánea a dos dispositivos"
                        isChecked: backend.dualConnection
                        onToggled: function(active) {
                            backend.setDualConnection(active)
                        }
                    }
                }

                // E. FIND MY EARBUDS CARD
                Card {
                    width: parent.width

                    Row {
                        spacing: 8
                        MaterialIcon {
                            name: "notifications_active"
                            size: 20
                            iconColor: "#0082c8"
                        }
                        Text {
                            text: "Localizar Auriculares"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "Emite una señal sonora para encontrar auriculares cercanos"
                        color: "#7e8694"
                        font.pixelSize: 11
                    }

                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "left", label: "Sonar Izq.", isStop: false },
                                { id: "right", label: "Sonar Der.", isStop: false },
                                { id: "both", label: "Ambos", isStop: false },
                                { id: "stop", label: "Detener", isStop: true }
                            ]
                            delegate: Rectangle {
                                width: (parent.width - (3 * 6)) / 4
                                height: 36
                                radius: 8
                                color: modelData.isStop ?
                                    (btnArea.containsMouse ? "#a8161e" : "#5c1318") :
                                    (btnArea.containsMouse ? "#0095e6" : "#1e2430")
                                border.color: modelData.isStop ? "#e01b24" : "#2d3545"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "#ffffff"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: btnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.findBuds(modelData.id)
                                }
                            }
                        }
                    }
                }

                // F. HARDWARE INFO CARD
                Card {
                    width: parent.width

                    Row {
                        spacing: 8
                        MaterialIcon {
                            name: "info"
                            size: 20
                            iconColor: "#0082c8"
                        }
                        Text {
                            text: "Información del Dispositivo"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "Versión de Protocolo:"
                            color: "#8c93a0"
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: backend.profileVersion
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "Identificador de Hardware:"
                            color: "#8c93a0"
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: backend.hardwareInfo
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }
    }

    // 3. FLOATING TOAST NOTIFICATION
    Rectangle {
        id: toastBanner
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.toastVisible ? 24 : -60
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(toastRow.implicitWidth + 32, parent.width - 32)
        height: 44
        radius: 22
        color: window.toastIsError ? "#471518" : "#103222"
        border.color: window.toastIsError ? "#e01b24" : "#2ec27e"
        border.width: 1
        z: 99

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Row {
            id: toastRow
            anchors.centerIn: parent
            spacing: 8

            MaterialIcon {
                name: window.toastIsError ? "error" : "check_circle"
                size: 18
                iconColor: window.toastIsError ? "#e01b24" : "#2ec27e"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: window.toastText
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
            }
        }
    }
}
