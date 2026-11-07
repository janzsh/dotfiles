// Botón cuadrado con un glifo. `filled` lo pinta con `accent` (acción principal).
import QtQuick

Rectangle {
    id: btn

    property string icon: ""
    property int size: 32
    property int iconSize: 16
    property bool filled: false
    property color accent: Theme.mauve
    signal clicked()

    width: size; height: size
    radius: Math.round(size * 0.3)
    color: filled ? (ma.containsMouse ? Qt.lighter(accent, 1.1) : accent)
                  : (ma.containsMouse ? Theme.surface1 : Theme.surface0)

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.filled ? Theme.crust : Theme.text
        font { family: Theme.font; pixelSize: btn.iconSize }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
