import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root

    property string currentMode: "Off"
    signal modeSelected(string mode)

    implicitHeight: gridLayout.implicitHeight
    implicitWidth: 400

    Grid {
        id: gridLayout
        width: parent.width
        columns: parent.width >= 500 ? 2 : 1
        spacing: 10

        Repeater {
            model: [
                {
                    id: "Off",
                    label: "Desactivado",
                    desc: "Audio directo sin filtros de ruido",
                    icon: "volume_off"
                },
                {
                    id: "NoiseCancellation",
                    label: "Cancelación de Ruido",
                    desc: "Bloqueo activo del ruido ambiental",
                    icon: "noise_aware"
                },
                {
                    id: "Adaptive",
                    label: "Modo Adaptativo",
                    desc: "Ajuste dinámico según el entorno",
                    icon: "tune"
                },
                {
                    id: "Transparency",
                    label: "Transparencia",
                    desc: "Paso de voz y sonidos exteriores",
                    icon: "hearing"
                }
            ]

            delegate: Rectangle {
                id: cardBtn
                width: gridLayout.columns === 2 ? (gridLayout.width - gridLayout.spacing) / 2 : gridLayout.width
                height: 68
                radius: 10

                property bool isSelected: root.currentMode === modelData.id
                color: isSelected ? "#0f3248" : (ancMouse.containsMouse ? "#20252f" : "#171a22")
                border.color: isSelected ? "#0082c8" : (ancMouse.containsMouse ? "#323a49" : "#252a36")
                border.width: isSelected ? 1.5 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 8
                        color: cardBtn.isSelected ? "#0082c8" : "#222733"
                        anchors.verticalCenter: parent.verticalCenter

                        MaterialIcon {
                            name: modelData.icon
                            size: 22
                            iconColor: cardBtn.isSelected ? "#ffffff" : "#a2a9b8"
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        width: parent.width - 54

                        Text {
                            text: modelData.label
                            color: cardBtn.isSelected ? "#ffffff" : "#eceff4"
                            font.pixelSize: 13
                            font.weight: cardBtn.isSelected ? Font.Bold : Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: modelData.desc
                            color: cardBtn.isSelected ? "#8bcbf5" : "#7b8392"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                MouseArea {
                    id: ancMouse
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
