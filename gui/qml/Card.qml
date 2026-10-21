import QtQuick

Rectangle {
    id: root

    default property alias contentData: contentLayout.data
    property int spacing: 14
    property int padding: 18

    color: "#13161d"
    radius: 14
    border.color: "#222733"
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
