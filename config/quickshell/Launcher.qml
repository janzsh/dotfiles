// Lanzador de aplicaciones: lee los .desktop vía DesktopEntries, filtra
// con un fuzzy simple y ordena por uso reciente (~/.cache/quickshell-launcher.json).
// Sin texto muestra una rejilla de "Frecuentes" (1-9 lanzan directo) y debajo
// todas las apps; al escribir queda solo la lista filtrada.
//
// Se abre por IPC:  qs ipc call launcher toggle   (bind en config/sway)
// Teclas: flechas, Tab/Shift+Tab, Ctrl+J/K navegar · Enter abrir · Esc cerrar

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool shown: false
    // Calentamiento: la primera apertura tardaba ~1 s (carga de .desktop,
    // iconos, superficie layer-shell). Se abre una vez, invisible y sin
    // capturar foco ni clics, poco después de arrancar.
    property bool warmup: true
    readonly property bool ghost: warmup && !shown
    readonly property int gridCols: 6
    readonly property int cellHeight: 100
    readonly property int rowHeight: 52
    readonly property real halfLife: 14 * 86400000   // ms; el uso viejo pesa menos

    // Rejilla de frecuentes (se recalcula al abrir, no mientras está abierto).
    property var frequent: []
    // Zona con el foco de navegación cuando se explora sin texto.
    property string area: "grid"
    readonly property bool showGrid: frequent.length > 0
    readonly property bool typing: search.text !== ""
    readonly property bool inGrid: showGrid && area === "grid"
    readonly property int maxVisible: 6

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }

    // Uso por id de .desktop: { c: lanzamientos, t: último (ms) }. El formato
    // antiguo era un número suelto; se migra al leer.
    FileView {
        id: usage
        path: Quickshell.env("HOME") + "/.cache/quickshell-launcher.json"
        property var counts: ({})
        onLoaded: {
            let c = {}
            try { c = JSON.parse(text()) } catch (e) {}
            const now = Date.now()
            for (const k in c)
                if (typeof c[k] === "number") c[k] = { c: c[k], t: now }
            counts = c
        }
    }

    // Lanzamientos con decaimiento exponencial (vida media = halfLife).
    function uses(id) {
        const u = usage.counts[id]
        return u ? u.c * Math.pow(0.5, (Date.now() - u.t) / root.halfLife) : 0
    }

    function refreshFrequent() {
        frequent = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && uses(e.id) >= 0.5)
            .sort((a, b) => uses(b.id) - uses(a.id))
            .slice(0, root.gridCols * 2)
        area = "grid"
        grid.currentIndex = 0
    }

    function score(entry, q) {
        const name = entry.name.toLowerCase()
        if (name.startsWith(q)) return 100
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 80
        if (name.includes(q)) return 60
        const extra = [entry.genericName, entry.comment, entry.execString,
                       Array.prototype.join.call(entry.keywords || [], " ")]
                      .join(" ").toLowerCase()
        if (extra.includes(q)) return 40
        let i = 0
        for (const ch of name) if (ch === q[i]) i++
        return i === q.length ? 20 : -1
    }

    function filter(query) {
        const q = query.trim().toLowerCase()
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({ e: e, s: q ? score(e, q) : 0, u: uses(e.id) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => (b.s + Math.min(b.u, 30)) - (a.s + Math.min(a.u, 30))
                            || a.e.name.localeCompare(b.e.name))
            .map(r => r.e)
    }

    function launch(entry) {
        if (!entry) return
        const c = Object.assign({}, usage.counts)
        c[entry.id] = { c: uses(entry.id) + 1, t: Date.now() }
        usage.counts = c
        usage.setText(JSON.stringify(c))

        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "--"].concat(entry.command))
        else
            entry.execute()
        root.shown = false
    }

    function move(dx, dy) {
        if (inGrid) {
            const n = grid.count, i = grid.currentIndex
            if (dx) grid.currentIndex = Math.max(0, Math.min(n - 1, i + dx))
            else if (dy < 0) grid.currentIndex = Math.max(0, i - root.gridCols)
            else if (i + root.gridCols < n) grid.currentIndex = i + root.gridCols
            else if (list.count > 0) { area = "list"; list.currentIndex = 0 }
        } else if (dy < 0 && showGrid && list.currentIndex === 0) {
            area = "grid"
        } else if (dy > 0) {
            list.incrementCurrentIndex()
        } else if (dy < 0) {
            list.decrementCurrentIndex()
        }
    }

    Timer { running: true; interval: 2500; onTriggered: root.warmup = false }

    PanelWindow {
        id: win
        visible: root.shown || root.warmup
        mask: root.ghost ? emptyMask : null
        Region { id: emptyMask }
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-launcher"
        WlrLayershell.keyboardFocus: root.ghost ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) {
            search.text = ""
            refreshFrequent()
            list.currentIndex = 0
            search.forceActiveFocus()
            intro.restart()
        }

        // Fondo atenuado; clic fuera cierra.
        Rectangle {
            anchors.fill: parent
            visible: !root.ghost
            color: Theme.crust
            opacity: 0.35
            MouseArea { anchors.fill: parent; onClicked: root.shown = false }
        }

        Rectangle {
            id: card
            visible: !root.ghost
            width: Math.min(640, parent.width - 48)
            height: content.implicitHeight + 20
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.14)
            radius: 16
            color: Theme.base
            border.width: 1
            border.color: Theme.surface0
            clip: true

            // Tragarse los clics para que no lleguen al fondo.
            MouseArea { anchors.fill: parent }

            ParallelAnimation {
                id: intro
                NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 90; easing.type: Easing.OutCubic }
                NumberAnimation { target: card; property: "scale"; from: 0.97; to: 1; duration: 110; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: content
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                spacing: 8

                // Buscador
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    implicitHeight: 44
                    radius: 11
                    color: Theme.mantle
                    border.width: 1
                    border.color: search.activeFocus ? Qt.alpha(Theme.mauve, 0.45) : "transparent"

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Text {
                            text: ""
                            color: Theme.mauve
                            font { family: Theme.font; pixelSize: 15 }
                        }

                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            color: Theme.text
                            selectionColor: Theme.surface2
                            selectedTextColor: Theme.text
                            font { family: Theme.font; pixelSize: 14 }
                            clip: true
                            onTextChanged: { list.currentIndex = 0; root.area = text ? "list" : "grid" }

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier
                                if (event.key === Qt.Key_Escape) {
                                    root.shown = false
                                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                                           || (ctrl && event.key === Qt.Key_J)) {
                                    root.move(0, 1)
                                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                                           || (ctrl && event.key === Qt.Key_K)) {
                                    root.move(0, -1)
                                } else if (root.inGrid && event.key === Qt.Key_Right) {
                                    root.move(1, 0)
                                } else if (root.inGrid && event.key === Qt.Key_Left) {
                                    root.move(-1, 0)
                                } else if (!root.typing && root.showGrid && event.key >= Qt.Key_1 && event.key <= Qt.Key_9
                                           && !(event.modifiers & ~Qt.KeypadModifier)) {
                                    root.launch(root.frequent[event.key - Qt.Key_1])
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.launch(root.inGrid ? root.frequent[grid.currentIndex]
                                                            : list.model[list.currentIndex])
                                } else {
                                    return
                                }
                                event.accepted = true
                            }
                        }

                        Text {
                            text: list.count
                            color: Theme.overlay1
                            font { family: Theme.font; pixelSize: 11 }
                        }
                    }
                }

                // Frecuentes
                Text {
                    visible: root.showGrid
                    Layout.leftMargin: 6
                    text: "Frecuentes"
                    color: Theme.overlay1
                    font { family: Theme.font; pixelSize: 11; weight: Font.Medium }
                }

                GridView {
                    id: grid
                    visible: root.showGrid
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? Math.ceil(count / root.gridCols) * root.cellHeight : 0
                    cellWidth: width / root.gridCols
                    cellHeight: root.cellHeight
                    interactive: false
                    model: root.frequent
                    highlightMoveDuration: 0

                    highlight: Rectangle {
                        visible: root.inGrid
                        radius: 12
                        color: Theme.surface0
                    }

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        width: GridView.view.cellWidth
                        height: root.cellHeight

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitSize: 48
                                source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                            }
                            Text {
                                width: cell.width - 10
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                color: root.inGrid && cell.GridView.isCurrentItem ? Theme.text : Theme.subtext1
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: 11 }
                            }
                        }

                        Text {
                            visible: cell.index < 9
                            x: 8; y: 6
                            text: cell.index + 1
                            color: Theme.overlay0
                            font { family: Theme.font; pixelSize: 9 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { root.area = "grid"; grid.currentIndex = cell.index }
                            onClicked: root.launch(cell.modelData)
                        }
                    }
                }

                Text {
                    visible: root.showGrid
                    Layout.leftMargin: 6
                    text: root.typing ? "Resultados" : "Todas las aplicaciones"
                    color: Theme.overlay1
                    font { family: Theme.font; pixelSize: 11; weight: Font.Medium }
                }

                // Resultados
                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: Math.max(1, Math.min(count, root.maxVisible)) * root.rowHeight
                    clip: true
                    spacing: 0
                    keyNavigationWraps: true
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 90
                    model: (root.shown || root.warmup) ? root.filter(search.text) : []

                    highlight: Rectangle {
                        visible: !root.inGrid
                        radius: 10
                        color: Theme.surface0
                        Rectangle {
                            x: 0; width: 3; height: 18; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.mauve
                        }
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: ListView.isCurrentItem && !root.inGrid
                        width: ListView.view.width
                        height: root.rowHeight

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                            spacing: 12

                            IconImage {
                                implicitSize: 36
                                source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    color: row.selected ? Theme.text : Theme.subtext1
                                    elide: Text.ElideRight
                                    font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.genericName || row.modelData.comment
                                    visible: text !== ""
                                    color: Theme.overlay1
                                    elide: Text.ElideRight
                                    font { family: Theme.font; pixelSize: 11 }
                                }
                            }

                            Text {
                                text: "\u{f0311}"
                                visible: row.selected
                                color: Theme.mauve
                                font { family: Theme.font; pixelSize: 14 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { root.area = "list"; list.currentIndex = row.index }
                            onClicked: root.launch(row.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        text: "Sin resultados"
                        color: Theme.overlay0
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
            }
        }
    }
}
