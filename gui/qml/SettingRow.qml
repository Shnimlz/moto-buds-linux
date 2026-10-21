import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root

    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property alias isChecked: toggleSwitch.checked
    property bool showSwitch: true
    signal toggled(bool active)

    implicitWidth: 400
    implicitHeight: 56

    Row {
        anchors.left: parent.left
        anchors.right: toggleSwitch.visible ? toggleSwitch.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Rectangle {
            width: 38
            height: 38
            radius: 8
            color: "#232731"
            anchors.verticalCenter: parent.verticalCenter

            MaterialIcon {
                name: root.iconName
                size: 20
                iconColor: "#dcdfe4"
                anchors.centerIn: parent
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: parent.width - 50

            Text {
                text: root.title
                color: "#f0f2f5"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.subtitle
                color: "#7e8694"
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width
                visible: root.subtitle.length > 0
            }
        }
    }

    Switch {
        id: toggleSwitch
        visible: root.showSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onToggled: root.toggled(checked)

        indicator: Rectangle {
            implicitWidth: 42
            implicitHeight: 24
            radius: 12
            color: toggleSwitch.checked ? "#0082c8" : "#2a2f3a"
            border.color: toggleSwitch.checked ? "#0095e6" : "#3d4452"
            border.width: 1

            Rectangle {
                x: toggleSwitch.checked ? parent.width - width - 2 : 2
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 10
                color: "#ffffff"

                Behavior on x {
                    NumberAnimation { duration: 120 }
                }
            }
        }
    }
}
