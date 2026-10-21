import QtQuick

Text {
    id: root

    property string name: ""
    property int size: 22
    property color iconColor: "#dcdfe4"

    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    text: name
    color: iconColor
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
