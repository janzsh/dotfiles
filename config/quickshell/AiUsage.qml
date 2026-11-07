// Consumo de tokens de herramientas de IA, en una ventana completa (como PowerMenu)
// con carrusel de dos vistas: Claude Code y Antigravity (agy).
// Los datos los calcula ai-usage.py (lee ~/.claude y ~/.gemini) cada minuto y al abrir.
// Se abre desde el botón de la barra o por IPC:  qs ipc call ai toggle | next | prev
// Teclas: ← → cambiar vista · r refrescar · Esc cerrar (también la rueda del mouse).

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool shown: false
    property int page: 0
    readonly property int pages: 2
    function go(n) { page = (page + n + pages) % pages }

    property var data: ({ claude: null, agy: null })
    readonly property var cl: data.claude
    readonly property var ag: data.agy

    function total(o) { return o ? o.in + o.out + o.cr + o.cw : 0 }
    function fmt(n) {
        return n >= 1e9 ? (n / 1e9).toFixed(2) + "B"
             : n >= 1e6 ? (n / 1e6).toFixed(1) + "M"
             : n >= 1e3 ? (n / 1e3).toFixed(0) + "K" : String(Math.round(n))
    }
    readonly property var today: cl ? cl.days[cl.days.length - 1] : null

    IpcHandler {
        target: "ai"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
        function next(): void { root.go(1) }
        function prev(): void { root.go(-1) }
    }

    Process {
        id: collector
        command: ["python3", "-I", Quickshell.shellPath("ai-usage.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text) } catch (e) { /* salida a medias: se conserva lo anterior */ }
            }
        }
    }
    function refresh() { if (!collector.running) collector.running = true }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    onShownChanged: if (shown) refresh()

    // ── componentes de dibujo ────────────────────────────────────────────────
    component Card: Rectangle {
        radius: 14
        color: Theme.mantle
        border.width: 1
        border.color: Theme.surface0
    }

    component Label: Text {
        color: Theme.subtext0
        font { family: Theme.font; pixelSize: 12 }
    }

    component Kpi: Card {
        property string title
        property string value
        property string sub: ""
        property color accent: Theme.mauve
        Layout.fillWidth: true
        implicitHeight: 92
        Column {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 4
            Label { text: title }
            Text { text: value; color: accent; font { family: Theme.font; pixelSize: 26; weight: Font.Bold } }
            Label { text: sub; visible: sub !== ""; color: Theme.overlay1; font.pixelSize: 11 }
        }
    }

    // Barras verticales (últimos días / horas de hoy). `values` es un arreglo de números.
    component BarChart: Item {
        property var values: []
        property var labels: []
        property color accent: Theme.mauve
        property int highlight: -1
        readonly property real maxV: Math.max(1, ...values)
        Row {
            id: barsRow
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: axis.top; bottomMargin: 6 }
            spacing: 4
            Repeater {
                model: values.length
                Item {
                    required property int index
                    width: (barsRow.width - 4 * (values.length - 1)) / Math.max(1, values.length)
                    height: barsRow.height
                    Rectangle { anchors.fill: parent; radius: 4; color: Theme.surface0; opacity: 0.5 }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: values[index] > 0 ? Math.max(3, parent.height * values[index] / maxV) : 0
                        radius: 4
                        color: index === highlight ? accent : Qt.alpha(accent, 0.55)
                        Behavior on height { NumberAnimation { duration: 200 } }
                    }
                    HoverHandler { id: hv }
                    Rectangle {
                        visible: hv.hovered && values[index] > 0
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom
                                  bottomMargin: Math.max(3, parent.height * values[index] / maxV) + 4 }
                        width: tip.implicitWidth + 12; height: 22; radius: 6
                        color: Theme.crust; border.width: 1; border.color: Theme.surface1
                        z: 10
                        Text { id: tip; anchors.centerIn: parent; text: root.fmt(values[index]); color: Theme.text
                               font { family: Theme.font; pixelSize: 11 } }
                    }
                }
            }
        }
        Row {
            id: axis
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 14
            spacing: 4
            Repeater {
                model: labels.length
                Text {
                    required property int index
                    width: (axis.width - 4 * (labels.length - 1)) / Math.max(1, labels.length)
                    horizontalAlignment: Text.AlignHCenter
                    text: labels[index]
                    color: index === highlight ? Theme.text : Theme.overlay0
                    font { family: Theme.font; pixelSize: 10 }
                }
            }
        }
    }

    // Fila "nombre ····· barra · valor" para modelos y proyectos.
    component RankRow: RowLayout {
        property string name
        property real value
        property real maxValue: 1
        property color accent: Theme.mauve
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: name; elide: Text.ElideMiddle; color: Theme.text
            Layout.preferredWidth: 190
            font { family: Theme.font; pixelSize: 12 }
        }
        Rectangle {
            Layout.fillWidth: true; height: 6; radius: 3; color: Theme.surface0
            Rectangle { width: parent.width * Math.min(1, value / Math.max(1, maxValue)); height: 6; radius: 3; color: accent }
        }
        Text {
            text: root.fmt(value); color: Theme.subtext1
            Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight
            font { family: Theme.font; pixelSize: 12 }
        }
    }

    function dayLabels(days) {
        return days.map(d => d.day.slice(8))
    }

    // ── ventana ──────────────────────────────────────────────────────────────
    PanelWindow {
        visible: root.shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-ai"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
            opacity: 0.55
            MouseArea { anchors.fill: parent; onClicked: root.shown = false }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Escape: root.shown = false; break
                case Qt.Key_Left: root.go(-1); break
                case Qt.Key_Right: root.go(1); break
                case Qt.Key_R: root.refresh(); break
                default: return
                }
                event.accepted = true
            }
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 980)
            height: Math.min(parent.height - 80, 760)
            radius: 20
            color: Theme.base
            border.width: 1
            border.color: Theme.surface0

            MouseArea {
                anchors.fill: parent
                onWheel: wheel => root.go(wheel.angleDelta.y < 0 ? 1 : -1)
            }

            ColumnLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 16

                // Cabecera: título de la vista + cerrar
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.page === 0 ? "\u{f06a9}  Claude Code" : "\u{f06a9}  Antigravity (agy)"
                        color: root.page === 0 ? Theme.peach : Theme.sky
                        font { family: Theme.font; pixelSize: 22; weight: Font.Bold }
                    }
                    Label {
                        text: root.data.updated ? "actualizado " + root.data.updated.slice(11, 16) : "cargando…"
                        color: Theme.overlay1
                        Layout.leftMargin: 10
                    }
                    Item { Layout.fillWidth: true }
                    IconButton { icon: "\u{f0450}"; size: 32; onClicked: root.refresh() }
                    IconButton { icon: "\u{f0156}"; size: 32; onClicked: root.shown = false }
                }

                // ── Vista 0: Claude Code ──
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: root.page === 0
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Kpi { title: "Hoy"; value: root.fmt(root.total(root.today)); sub: root.today ? root.today.msgs + " respuestas" : ""; accent: Theme.peach }
                        Kpi { title: "Últimas 5 h"; value: root.fmt(root.total(root.cl && root.cl.window5h)); sub: root.cl ? root.cl.window5h.msgs + " respuestas" : ""; accent: Theme.yellow }
                        Kpi { title: "Salida hoy"; value: root.fmt(root.today ? root.today.out : 0); sub: "tokens generados"; accent: Theme.mauve }
                        Kpi {
                            title: "Caché leída hoy"; value: root.fmt(root.today ? root.today.cr : 0); accent: Theme.ok
                            sub: root.today && root.total(root.today) > 0
                                 ? Math.round(root.today.cr / root.total(root.today) * 100) + "% del total" : ""
                        }
                    }

                    Card {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 1
                        ColumnLayout {
                            anchors { fill: parent; margins: 16 }
                            spacing: 8
                            Label { text: "Tokens por día (14 días, todo incluido)" }
                            BarChart {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                accent: Theme.peach
                                values: root.cl ? root.cl.days.map(d => root.total(d)) : []
                                labels: root.cl ? root.dayLabels(root.cl.days) : []
                                highlight: root.cl ? root.cl.days.length - 1 : -1
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 1
                        spacing: 12
                        Card {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            ColumnLayout {
                                anchors { fill: parent; margins: 16 }
                                spacing: 8
                                Label { text: "Hoy por hora" }
                                BarChart {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    accent: Theme.mauve
                                    values: root.cl ? root.cl.hours.map(h => root.total(h)) : []
                                    labels: root.cl ? root.cl.hours.map(h => h.hour % 6 === 0 ? String(h.hour) : "") : []
                                    highlight: new Date().getHours()
                                }
                            }
                        }
                        Card {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            ColumnLayout {
                                anchors { fill: parent; margins: 16 }
                                spacing: 8
                                Label { text: "Modelos" }
                                Repeater {
                                    model: root.cl ? root.cl.models.slice(0, 3) : []
                                    RankRow {
                                        required property var modelData
                                        name: modelData.name; value: root.total(modelData)
                                        maxValue: root.cl.models.length ? root.total(root.cl.models[0]) : 1
                                        accent: Theme.peach
                                    }
                                }
                                Label { text: "Proyectos"; Layout.topMargin: 6 }
                                Repeater {
                                    model: root.cl ? root.cl.projects.slice(0, 4) : []
                                    RankRow {
                                        required property var modelData
                                        name: modelData.name; value: root.total(modelData)
                                        maxValue: root.cl.projects.length ? root.total(root.cl.projects[0]) : 1
                                        accent: Theme.mauve
                                    }
                                }
                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }

                // ── Vista 1: Antigravity ──
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: root.page === 1
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Kpi { title: "Conversaciones"; value: root.ag ? String(root.ag.conversations) : "—"; sub: "guardadas en agy"; accent: Theme.sky }
                        Kpi {
                            title: "Pasos (14 días)"; accent: Theme.blue
                            value: root.ag ? String(root.ag.days.reduce((a, d) => a + d.steps, 0)) : "—"
                            sub: "acciones del agente"
                        }
                        Kpi {
                            title: "Sesión"; accent: root.ag && root.ag.loggedIn ? Theme.green : Theme.red
                            value: root.ag ? (root.ag.loggedIn ? "activa" : "sin login") : "—"
                            sub: root.ag && !root.ag.loggedIn ? "ejecuta agy para iniciar sesión" : ""
                        }
                        Kpi {
                            title: "Tokens"; accent: Theme.overlay1
                            value: root.ag && root.ag.tokensAvailable ? "ok" : "sin datos"
                            sub: "agy aún no los registra"
                        }
                    }

                    Card {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        ColumnLayout {
                            anchors { fill: parent; margins: 16 }
                            spacing: 8
                            Label { text: "Actividad por día (pasos del agente, 14 días)" }
                            BarChart {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                accent: Theme.sky
                                values: root.ag ? root.ag.days.map(d => d.steps) : []
                                labels: root.ag ? root.dayLabels(root.ag.days) : []
                                highlight: root.ag ? root.ag.days.length - 1 : -1
                            }
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                color: Theme.overlay1
                                text: "Antigravity guarda sus conversaciones en ~/.gemini/antigravity-cli pero no escribe contadores de tokens en claro. Cuando lo haga, ai-usage.py los leerá de gen_metadata y esta vista mostrará tokens."
                            }
                        }
                    }
                }

                // Carrusel: flechas + puntos
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    Text {
                        text: "󰅁"; color: prevMa.containsMouse ? Theme.text : Theme.overlay1
                        font { family: Theme.font; pixelSize: Theme.iconSize }
                        MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: root.go(-1) }
                    }
                    Repeater {
                        model: root.pages
                        Rectangle {
                            Layout.preferredWidth: index === root.page ? 16 : 6
                            Layout.preferredHeight: 6
                            radius: 3
                            color: index === root.page ? (root.page === 0 ? Theme.peach : Theme.sky) : Theme.surface2
                            Behavior on Layout.preferredWidth { NumberAnimation { duration: 150 } }
                        }
                    }
                    Text {
                        text: "󰅂"; color: nextMa.containsMouse ? Theme.text : Theme.overlay1
                        font { family: Theme.font; pixelSize: Theme.iconSize }
                        MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: root.go(1) }
                    }
                }
            }
        }
    }
}
