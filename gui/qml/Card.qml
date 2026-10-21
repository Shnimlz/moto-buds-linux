import QtQuick

Rectangle {
    id: root

    default property alias contentData: contentLayout.data
    property int spacing: 12
    property int padding: 16

    color: "#181a1f"
    radius: 14
    border.color: "#282c34"
    border.width: 1

    implicitWidth: 400
    implicitHeight: contentLayout.implicitHeight + (padding * 2)

    Column {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.spacing
    }
}
