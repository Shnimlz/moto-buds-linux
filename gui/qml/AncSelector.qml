import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: root

    property string currentMode: "Off"
    signal modeSelected(string mode)

    color: "#181a1f"
    radius: 12
    border.color: "#282c34"
    border.width: 1
    implicitHeight: 72
    implicitWidth: 400

    Row {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: [
                { id: "Off", label: "Desactivado", icon: "volume_off" },
                { id: "NoiseCancellation", label: "Cancelación", icon: "noise_aware" },
                { id: "Adaptive", label: "Adaptativo", icon: "tune" },
                { id: "Transparency", label: "Transparente", icon: "hearing" }
            ]

            delegate: Rectangle {
                id: segBtn
                width: (parent.width - (3 * 4)) / 4
                height: parent.height
                radius: 8

                property bool isSelected: root.currentMode === modelData.id
                color: isSelected ? "#0082c8" : (mouseArea.containsMouse ? "#232730" : "transparent")

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        name: modelData.icon
                        size: 20
                        iconColor: segBtn.isSelected ? "#ffffff" : "#a0a6b5"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: modelData.label
                        color: segBtn.isSelected ? "#ffffff" : "#8c93a0"
                        font.pixelSize: 10
                        font.weight: segBtn.isSelected ? Font.Bold : Font.Normal
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.currentMode !== modelData.id) {
                            root.modeSelected(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
