// Menú del logo de Nix: clic o hover abren el panel (ver HoverPopup). Tiene
// el lanzador y apps favoritas.

import Quickshell
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    required property var launcherRef

    // Apps favoritas: edita esta lista para cambiarlas.
    readonly property var favorites: [
        { label: "Terminal", icon: "\u{f489}",  color: Theme.ok, cmd: ["kitty"] },
        { label: "Firefox",  icon: "\u{f0239}", color: Theme.peach, cmd: ["firefox"] },
        { label: "Archivos", icon: "\u{f024b}", color: Theme.blue,  cmd: ["nautilus"] }
    ]

    openDelay: 500
    popupWidth: 260
    alignLeft: true
    implicitWidth: 30
    implicitHeight: 30

    function run(cmd) {
        root.close()
        Quickshell.execDetached(cmd)
    }

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.hovered || root.launcherRef.shown ? Theme.surface0 : "transparent"
        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(0xF313)
            color: Theme.mauve
            font { family: Theme.font; pixelSize: Theme.iconSize }
        }
    }

    // Fila de menú genérica.
    component Entry: Rectangle {
        id: entry
        property string icon
        property string label
        property color tint: Theme.mauve
        property string trail: ""
        signal activated()

        Layout.fillWidth: true
        height: 36
        radius: 10
        color: ma.containsMouse ? Theme.surface0 : "transparent"

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 10
            Text {
                text: entry.icon
                color: entry.tint
                font { family: Theme.font; pixelSize: 16 }
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                text: entry.label
                color: Theme.text
                font { family: Theme.font; pixelSize: 13 }
                Layout.fillWidth: true
            }
            Text {
                text: entry.trail
                color: Theme.overlay1
                font { family: Theme.font; pixelSize: 12 }
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.activated()
        }
    }

    popup: Component {
        ColumnLayout {
            spacing: 4
            implicitHeight: childrenRect.height

            Entry {
                icon: "\u{f0349}"   // apps
                label: "Aplicaciones"
                trail: "Super+M"
                onActivated: { root.close(); root.launcherRef.shown = true }
            }

            Text {
                text: "Favoritas"
                color: Theme.subtext0
                font { family: Theme.font; pixelSize: 11 }
                Layout.topMargin: 8
                Layout.leftMargin: 10
            }

            Repeater {
                model: root.favorites
                Entry {
                    required property var modelData
                    icon: modelData.icon
                    label: modelData.label
                    tint: modelData.color
                    onActivated: root.run(modelData.cmd)
                }
            }
        }
    }
}
