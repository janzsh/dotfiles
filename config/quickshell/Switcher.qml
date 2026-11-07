// Selector de ventanas del workspace actual (estilo Alt+Tab de Windows).
// Lista las ventanas de `windows` (wm-state-bridge.sh) y se maneja con teclado.
//
// Se abre por IPC:  qs ipc call switcher toggle   (mod+Tab en config/sway)
// Teclas: Tab/↓/→/J siguiente · Shift+Tab/↑/←/K anterior · 1-9 directo
//         Enter enfocar · Esc cerrar

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

Scope {
    id: root

    // [{app, id, title, focused}] del workspace enfocado
    property var windows: []

    property bool shown: false
    property var items: []          // copia al abrir: no se mueve mientras eliges
    property int current: 0

    readonly property int rowHeight: 48
    readonly property int maxVisible: 8

    IpcHandler {
        target: "switcher"
        function toggle(): void { root.shown ? root.close() : root.open() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    function open() {
        if (windows.length === 0) return
        items = windows.slice()
        const f = items.findIndex(w => w.focused)
        current = items.length > 1 ? (f + 1) % items.length : 0   // arranca en la siguiente
        shown = true
    }
    function close() { shown = false }
    function move(d) { current = (current + d + items.length) % items.length }
    function accept() {
        const w = items[current]
        close()
        if (w) Quickshell.execDetached([Quickshell.shellDir + "/wmctl.sh", "focus", String(w.id)])
    }
    function iconFor(app) {
        const e = DesktopEntries.heuristicLookup(app)
        return Quickshell.iconPath(e ? e.icon : app.toLowerCase(), "application-x-executable")
    }

    PanelWindow {
        id: win
        visible: root.shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-switcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        // Clic fuera cierra.
        MouseArea { anchors.fill: parent; onClicked: root.close() }

        FocusScope {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                const k = event.key
                const shift = event.modifiers & Qt.ShiftModifier
                if (k === Qt.Key_Escape) root.close()
                else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.accept()
                else if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && shift)
                         || k === Qt.Key_Up || k === Qt.Key_Left || k === Qt.Key_K) root.move(-1)
                else if (k === Qt.Key_Tab || k === Qt.Key_Down || k === Qt.Key_Right
                         || k === Qt.Key_J) root.move(1)
                else if (k >= Qt.Key_1 && k <= Qt.Key_9 && (k - Qt.Key_1) < root.items.length) {
                    root.current = k - Qt.Key_1
                    root.accept()
                } else return
                event.accepted = true
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 560
                height: Math.min(root.items.length, root.maxVisible) * root.rowHeight + 20
                radius: 16
                color: Qt.alpha(Theme.crust, 0.82)
                border.width: 1
                border.color: Qt.alpha(Theme.surface1, 0.6)

                // evita que el clic sobre la tarjeta llegue al fondo y la cierre
                MouseArea { anchors.fill: parent }

                ListView {
                    id: list
                    anchors { fill: parent; margins: 10 }
                    clip: true
                    model: root.items
                    currentIndex: root.current
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    interactive: false

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: root.rowHeight
                        radius: 11
                        color: index === root.current ? Qt.alpha(Theme.mauve, 0.28)
                             : rowMa.containsMouse ? Qt.alpha(Theme.surface1, 0.6) : "transparent"
                        border.width: index === root.current ? 1 : 0
                        border.color: Qt.alpha(Theme.mauve, 0.7)

                        IconImage {
                            id: ico
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 30
                            source: root.iconFor(row.modelData.app)
                        }
                        Column {
                            anchors {
                                left: ico.right; leftMargin: 12
                                right: num.left; rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 1
                            Text {
                                width: parent.width
                                text: row.modelData.title || row.modelData.app
                                color: Theme.text
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: 13 }
                            }
                            Text {
                                width: parent.width
                                text: row.modelData.app + (row.modelData.focused ? "  ·  actual" : "")
                                color: Theme.overlay1
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: 11 }
                            }
                        }
                        Text {
                            id: num
                            visible: row.index < 9
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            text: row.index + 1
                            color: Theme.overlay0
                            font { family: Theme.font; pixelSize: 12 }
                        }
                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { root.current = row.index; root.accept() }
                        }
                    }
                }
            }
        }
    }
}
