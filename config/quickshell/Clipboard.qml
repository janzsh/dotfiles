// Historial del portapapeles (cliphist). Se abre desde el menú del logo de
// Nix o por IPC:  qs ipc call clipboard toggle
// El historial lo llena `wl-paste --watch cliphist store` (config/sway).
// Teclas: ↑/↓ navegar · Enter copiar · Supr borrar entrada · Esc cerrar

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool shown: false
    property var items: []      // { id, text }
    property int current: 0
    readonly property int maxItems: 100

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }

    onShownChanged: if (shown) { current = 0; list.running = true }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.items = text.split("\n").filter(l => l).slice(0, root.maxItems).map(l => {
                    const tab = l.indexOf("\t")
                    return { id: l.slice(0, tab), text: l.slice(tab + 1) }
                })
            }
        }
    }

    function copy(item) {
        root.shown = false
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + item.id + " | wl-copy"])
    }

    function remove(item) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' " + item.id + " | cliphist delete"])
        root.items = root.items.filter(i => i.id !== item.id)
        root.current = Math.min(root.current, Math.max(0, root.items.length - 1))
    }

    PanelWindow {
        visible: root.shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-launcher"   // reutiliza el blur de sway
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
            opacity: 0.45
            MouseArea { anchors.fill: parent; onClicked: root.shown = false }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                const n = root.items.length
                if (event.key === Qt.Key_Escape) root.shown = false
                else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier)))
                    root.current = Math.min(n - 1, root.current + 1)
                else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)))
                    root.current = Math.max(0, root.current - 1)
                else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && n > 0)
                    root.copy(root.items[root.current])
                else if (event.key === Qt.Key_Delete && n > 0)
                    root.remove(root.items[root.current])
                else return
                event.accepted = true
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 560
            height: Math.min(parent.height - 120, 56 + Math.max(1, root.items.length) * 40 + 24)
            radius: 16
            color: Qt.alpha(Theme.base, 0.94)
            border.width: 1
            border.color: Qt.alpha(Theme.surface2, 0.6)

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "\u{f0ea}  Portapapeles"
                        color: Theme.yellow
                        font { family: Theme.font; pixelSize: 15; weight: Font.Bold }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Enter copiar · Supr borrar · Esc cerrar"
                        color: Theme.overlay0
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }

                Text {
                    visible: root.items.length === 0
                    text: "Historial vacío"
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 13 }
                    Layout.topMargin: 8
                }

                ListView {
                    id: view
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.items
                    currentIndex: root.current
                    highlightMoveDuration: 0
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: view.width
                        height: 36
                        radius: 10
                        color: index === root.current || ma.containsMouse ? Theme.surface0 : "transparent"
                        Text {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.text.replace(/\s+/g, " ")
                            color: Theme.text
                            elide: Text.ElideRight
                            font { family: Theme.font; pixelSize: 13 }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.current = index
                            onClicked: root.copy(modelData)
                        }
                    }
                }
            }
        }
    }
}
