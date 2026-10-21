import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1040
    height: 760
    minimumWidth: 520
    minimumHeight: 580
    title: "Moto Buds"
    color: "#0a0c10"

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

        // 1. TOP DESKTOP HEADER BAR
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#11141b"
            border.color: "#1c212c"
            border.width: 1
            z: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16

                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        source: "qrc:/qt/qml/MotoBuds/assets/icon.png"
                        width: 28
                        height: 28
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Moto Buds"
                            color: "#ffffff"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }

                        Text {
                            text: backend.statusSubtitle
                            color: backend.connected ? "#2ec27e" : "#838b99"
                            font.pixelSize: 11
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Top Connection Badge
                Rectangle {
                    height: 26
                    width: topConnLabel.implicitWidth + 24
                    radius: 13
                    color: backend.connected ? "#143124" : "#30171a"
                    border.color: backend.connected ? "#2ec27e" : "#e01b24"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            color: backend.connected ? "#2ec27e" : "#e01b24"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: topConnLabel
                            text: backend.connected ? "Conectado" : "Desconectado"
                            color: backend.connected ? "#2ec27e" : "#e01b24"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Refresh Button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    color: refreshArea.containsMouse ? "#222733" : "#171a22"
                    border.color: "#272c38"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    MaterialIcon {
                        id: refreshIcon
                        name: "refresh"
                        size: 20
                        iconColor: backend.loading ? "#0082c8" : "#d2d6df"
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

        // 2. MAIN SCROLLABLE DASHBOARD
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: dashboardContainer.implicitHeight + 48
            clip: true

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Item {
                id: dashboardContainer
                width: Math.min(parent.width - 48, 1260)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 24

                readonly property bool isWideLayout: window.width >= 860

                implicitHeight: isWideLayout ?
                    Math.max(leftColumn.implicitHeight, rightColumn.implicitHeight) :
                    (leftColumn.implicitHeight + rightColumn.implicitHeight + 20)

                // LEFT COLUMN: Device, Battery & Finder
                Column {
                    id: leftColumn
                    width: dashboardContainer.isWideLayout ? 390 : parent.width
                    anchors.left: parent.left
                    anchors.top: parent.top
                    spacing: 16

                    // HERO & BATTERY CARD
                    Rectangle {
                        width: parent.width
                        height: heroContentCol.implicitHeight + 32
                        radius: 16
                        color: "#12151c"
                        border.color: "#1f2430"
                        border.width: 1

                        Column {
                            id: heroContentCol
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Image {
                                source: "qrc:/qt/qml/MotoBuds/assets/case_open_buds.webp"
                                width: 230
                                height: 180
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

                            // Battery Cards Row
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

                    // FIND MY EARBUDS CARD
                    Card {
                        width: parent.width

                        Row {
                            spacing: 10
                            MaterialIcon {
                                name: "notifications_active"
                                size: 22
                                iconColor: "#0082c8"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Column {
                                spacing: 1
                                Text {
                                    text: "Localizar Auriculares"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "Emite un tono progresivo para encontrarlos"
                                    color: "#7e8694"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 8

                            Repeater {
                                model: [
                                    { id: "left", label: "Sonar Izquierdo", isStop: false },
                                    { id: "right", label: "Sonar Derecho", isStop: false },
                                    { id: "both", label: "Sonar Ambos", isStop: false },
                                    { id: "stop", label: "Detener Alarma", isStop: true }
                                ]
                                delegate: Rectangle {
                                    width: (parent.width - 8) / 2
                                    height: 38
                                    radius: 8
                                    color: modelData.isStop ?
                                        (btnArea.containsMouse ? "#8c151c" : "#481519") :
                                        (btnArea.containsMouse ? "#0090e0" : "#1a202c")
                                    border.color: modelData.isStop ? "#e01b24" : "#2a3242"
                                    border.width: 1

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

                    // DEVICE INFO CARD
                    Card {
                        width: parent.width

                        Row {
                            spacing: 10
                            MaterialIcon {
                                name: "info"
                                size: 20
                                iconColor: "#0082c8"
                                anchors.verticalCenter: parent.verticalCenter
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
                                text: "Versión de Protocolo"
                                color: "#858d9c"
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
                                text: "Canal Bluetooth"
                                color: "#858d9c"
                                font.pixelSize: 12
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "RFCOMM Canal 16 (SPP)"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            width: parent.width
                            Text {
                                text: "Identificador de Hardware"
                                color: "#858d9c"
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

                // RIGHT COLUMN: ANC, Sound, Equalizer & Smart Features
                Column {
                    id: rightColumn
                    width: dashboardContainer.isWideLayout ? (parent.width - leftColumn.width - 20) : parent.width
                    anchors.left: dashboardContainer.isWideLayout ? leftColumn.right : parent.left
                    anchors.leftMargin: dashboardContainer.isWideLayout ? 20 : 0
                    anchors.top: dashboardContainer.isWideLayout ? parent.top : leftColumn.bottom
                    anchors.topMargin: dashboardContainer.isWideLayout ? 0 : 20
                    spacing: 16

                    // 1. NOISE CANCELLATION SECTION
                    Card {
                        width: parent.width

                        Row {
                            spacing: 10
                            MaterialIcon {
                                name: "noise_aware"
                                size: 22
                                iconColor: "#0082c8"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Column {
                                spacing: 1
                                Text {
                                    text: "Control de Ruido Activo (ANC)"
                                    color: "#ffffff"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "Selecciona el perfil de aislamiento acústico deseado"
                                    color: "#7e8694"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        AncSelector {
                            width: parent.width
                            currentMode: backend.ancMode
                            onModeSelected: function(mode) {
                                backend.setAncMode(mode)
                            }
                        }
                    }

                    // 2. SOUND & PERFORMANCE SECTION
                    Card {
                        width: parent.width

                        Row {
                            spacing: 10
                            MaterialIcon {
                                name: "graphic_eq"
                                size: 22
                                iconColor: "#0082c8"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Column {
                                spacing: 1
                                Text {
                                    text: "Sonido y Rendimiento"
                                    color: "#ffffff"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "Ajustes de latencia, perfil sonoro e inmersión acústica"
                                    color: "#7e8694"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        SettingRow {
                            width: parent.width
                            iconName: "sports_esports"
                            title: "Modo Juego (Baja Latencia)"
                            subtitle: "Minimiza la latencia de audio para sincronización en juegos y vídeos"
                            isChecked: backend.gameMode
                            onToggled: function(active) {
                                backend.setGameMode(active)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#1e222d"
                        }

                        // Spatial Audio
                        Column {
                            width: parent.width
                            spacing: 10

                            Row {
                                spacing: 14
                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 8
                                    color: "#1c212c"
                                    MaterialIcon {
                                        name: "surround_sound"
                                        size: 22
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
                                        text: "Inmersión acústica tridimensional"
                                        color: "#7e8694"
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: [
                                        { id: 0, label: "Desactivado", desc: "Estéreo convencional" },
                                        { id: 1, label: "Audio Espacial Fijo", desc: "Escena 3D estática" },
                                        { id: 2, label: "Seguimiento de Cabeza", desc: "Escena adaptativa al girar" }
                                    ]
                                    delegate: Rectangle {
                                        width: (parent.width - 16) / 3
                                        height: 52
                                        radius: 8
                                        property bool isSel: backend.spatialMode === modelData.id
                                        color: isSel ? "#0f3248" : (spMouse.containsMouse ? "#202531" : "#171a22")
                                        border.color: isSel ? "#0082c8" : (spMouse.containsMouse ? "#2f3745" : "#242934")
                                        border.width: isSel ? 1.5 : 1

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Text {
                                                text: modelData.label
                                                color: parent.parent.isSel ? "#ffffff" : "#d2d6df"
                                                font.pixelSize: 11
                                                font.weight: parent.parent.isSel ? Font.Bold : Font.DemiBold
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                            Text {
                                                text: modelData.desc
                                                color: parent.parent.isSel ? "#8bcbf5" : "#727988"
                                                font.pixelSize: 10
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: spMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: backend.setSpatialMode(modelData.id)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#1e222d"
                        }

                        // Equalizer Presets
                        Column {
                            width: parent.width
                            spacing: 10

                            Row {
                                spacing: 14
                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 8
                                    color: "#1c212c"
                                    MaterialIcon {
                                        name: "equalizer"
                                        size: 22
                                        anchors.centerIn: parent
                                    }
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: "Perfiles de Ecualización"
                                        color: "#f0f2f5"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: "Calibración de respuesta en frecuencia de fábrica"
                                        color: "#7e8694"
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            Grid {
                                width: parent.width
                                columns: 2
                                spacing: 8

                                Repeater {
                                    model: [
                                        { idx: 0, label: "Original", desc: "Curva plana de fábrica", icon: "graphic_eq" },
                                        { idx: 1, label: "Predeterminado", desc: "Ajuste equilibrado Motorola", icon: "equalizer" },
                                        { idx: 2, label: "Realce de Graves", desc: "Bajos profundos y contundentes", icon: "speaker" },
                                        { idx: 3, label: "Voces Claras", desc: "Claridad en medios y llamadas", icon: "record_voice_over" }
                                    ]
                                    delegate: Rectangle {
                                        width: (parent.width - 8) / 2
                                        height: 56
                                        radius: 8
                                        property bool isSel: backend.eqPreset === modelData.idx
                                        color: isSel ? "#0f3248" : (eqMouse.containsMouse ? "#202531" : "#171a22")
                                        border.color: isSel ? "#0082c8" : (eqMouse.containsMouse ? "#2f3745" : "#242934")
                                        border.width: isSel ? 1.5 : 1

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            MaterialIcon {
                                                name: modelData.icon
                                                size: 20
                                                iconColor: parent.parent.isSel ? "#0082c8" : "#8c94a4"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2
                                                width: parent.width - 32

                                                Text {
                                                    text: modelData.label
                                                    color: parent.parent.parent.isSel ? "#ffffff" : "#eceff4"
                                                    font.pixelSize: 12
                                                    font.weight: parent.parent.parent.isSel ? Font.Bold : Font.DemiBold
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.desc
                                                    color: parent.parent.parent.isSel ? "#8bcbf5" : "#727988"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: eqMouse
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

                    // 3. SMART FEATURES SECTION
                    Card {
                        width: parent.width

                        Row {
                            spacing: 10
                            MaterialIcon {
                                name: "psychology"
                                size: 22
                                iconColor: "#0082c8"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Column {
                                spacing: 1
                                Text {
                                    text: "Ajustes Inteligentes"
                                    color: "#ffffff"
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "Automatización de sensores y enlaces Bluetooth"
                                    color: "#7e8694"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        SettingRow {
                            width: parent.width
                            iconName: "hearing"
                            title: "Detección en Oreja"
                            subtitle: "Pausa automáticamente al quitarse un auricular y reanuda al volver a ponérselo"
                            isChecked: backend.inEarDetection
                            onToggled: function(active) {
                                backend.setInEarDetection(active)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#1e222d"
                        }

                        SettingRow {
                            width: parent.width
                            iconName: "devices"
                            title: "Conexión Dual Simultánea (Multipoint)"
                            subtitle: "Permite enlace Bluetooth activo al mismo tiempo con tu PC y tu teléfono"
                            isChecked: backend.dualConnection
                            onToggled: function(active) {
                                backend.setDualConnection(active)
                            }
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
        width: Math.min(toastRow.implicitWidth + 36, parent.width - 48)
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
