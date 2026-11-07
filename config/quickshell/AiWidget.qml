// Botón de IA en la barra: solo el icono. Clic abre AiUsage (`ai`), que muestra los tokens.
import QtQuick

Item {
    id: root

    required property var ai

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: ma.containsMouse || root.ai.shown ? Theme.surface0 : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{f06a9}"
            color: Theme.peach
            font { family: Theme.font; pixelSize: Theme.iconSize }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.ai.shown = !root.ai.shown
    }
}
