import QtQuick

Rectangle {
    id: root

    property string title: ""
    property string imageSource: ""
    property int percentage: -1
    property bool isCharging: false
    property bool connected: false

    color: "#161921"
    radius: 12
    border.color: isCharging ? "#0082c8" : "#262b36"
    border.width: isCharging ? 1.5 : 1

    implicitWidth: 110
    implicitHeight: 145

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Image {
            id: budImg
            source: root.imageSource
            width: 44
            height: 44
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            smooth: true
            opacity: root.connected && root.percentage >= 0 ? 1.0 : 0.4
        }

        Text {
            text: root.title
            color: "#858d9c"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3

            Text {
                text: root.percentage >= 0 ? root.percentage + "%" : "--%"
                color: root.isCharging ? "#2ec27e" : (root.connected ? "#ffffff" : "#636a78")
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            MaterialIcon {
                name: "bolt"
                size: 16
                iconColor: "#2ec27e"
                visible: root.isCharging
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Mini battery bar
        Rectangle {
            width: parent.width - 12
            height: 4
            radius: 2
            color: "#232834"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.connected && root.percentage >= 0

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.percentage)) / 100
                height: parent.height
                radius: 2
                color: root.isCharging ? "#2ec27e" : (root.percentage < 20 ? "#e01b24" : "#0082c8")
            }
        }

        Text {
            text: {
                if (!root.connected || root.percentage < 0) return "Desconectado";
                if (root.isCharging) return "Cargando";
                return "En uso";
            }
            color: root.isCharging ? "#2ec27e" : "#727987"
            font.pixelSize: 10
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
