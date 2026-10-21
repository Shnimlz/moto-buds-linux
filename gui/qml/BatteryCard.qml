import QtQuick

Rectangle {
    id: root

    property string title: ""
    property string imageSource: ""
    property int percentage: -1
    property bool isCharging: false
    property bool connected: false

    color: "#1e222b"
    radius: 12
    border.color: isCharging ? "#0082c8" : "#2d323c"
    border.width: isCharging ? 1.5 : 1

    implicitWidth: 120
    implicitHeight: 140

    Column {
        anchors.centerIn: parent
        spacing: 6
        width: parent.width - 16

        Image {
            id: budImg
            source: root.imageSource
            width: 48
            height: 48
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            smooth: true
            opacity: root.connected && root.percentage >= 0 ? 1.0 : 0.4
        }

        Text {
            text: root.title
            color: "#8c93a0"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3

            Text {
                text: root.percentage >= 0 ? root.percentage + "%" : "--%"
                color: root.isCharging ? "#2ec27e" : (root.connected ? "#ffffff" : "#6c7280")
                font.pixelSize: 17
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

        Text {
            text: {
                if (!root.connected || root.percentage < 0) return "Desconectado";
                if (root.isCharging) return "Cargando";
                return "En uso";
            }
            color: root.isCharging ? "#2ec27e" : "#8c93a0"
            font.pixelSize: 11
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
