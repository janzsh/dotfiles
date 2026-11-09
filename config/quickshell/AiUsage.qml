// Panel centrado de consumo de Claude Code, Codex y Antigravity.
// ai-usage.py lee sus registros locales y actualiza los datos cada minuto y al abrir.
// La gráfica muestra la semana actual o la anterior; Antigravity estima 100K tokens por paso.
// Se abre desde la barra o por IPC: qs ipc call ai toggle | open | close
// Teclas: R actualiza los datos, ←/→ cambian de semana y Esc cierra el panel.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool shown: false
    property int weekOffset: 0      // 0 = semana actual, 1 = semana anterior
    property var data: ({ claude: null, codex: null, agy: null })
    readonly property var cl: data.claude
    readonly property var cx: data.codex
    readonly property var ag: data.agy
    readonly property var todayClaude: cl ? cl.days[cl.days.length - 1] : null
    readonly property var todayCodex: cx ? cx.days[cx.days.length - 1] : null
    readonly property var primary: cx && cx.limits ? cx.limits.primary : null
    readonly property var secondary: cx && cx.limits ? cx.limits.secondary : null
    function total(o) { return o ? o.in + o.out + o.cr + o.cw : 0 }
    function fmt(n) {
        return n >= 1e9 ? (n / 1e9).toFixed(2) + "B"
             : n >= 1e6 ? (n / 1e6).toFixed(1) + "M"
             : n >= 1e3 ? (n / 1e3).toFixed(0) + "K" : String(Math.round(n))
    }
    function limitValue(limit) { return limit && limit.used_percent != null ? Math.round(limit.used_percent) + "% usado" : "Sin datos" }
    function limitTitle(limit, fallback) {
        if (!limit || !limit.window_minutes) return fallback
        let m = limit.window_minutes
        return m % 1440 === 0 ? (m / 1440) + " días" : m % 60 === 0 ? (m / 60) + " h" : m + " min"
    }
    function limitReset(limit) {
        return limit && limit.resets_at ? "reinicia " + new Date(limit.resets_at * 1000).toLocaleString(Qt.locale(), "dd/MM HH:mm") : "sin reinicio registrado"
    }
    // El colector incluye hoy y los 13 días anteriores: alcanza para la semana
    // anterior completa. Los días futuros quedan en cero para mantener el eje
    // de lunes a domingo.
    function weekValues(days, field, offset) {
        const result = [0, 0, 0, 0, 0, 0, 0]
        if (!days || !days.length) return result
        const today = new Date(days[days.length - 1].day + "T12:00:00")
        const start = days.length - 1 - (today.getDay() + 6) % 7 - 7 * offset
        for (let i = 0; i < 7; i++) {
            const entry = start + i >= 0 && start + i < days.length ? days[start + i] : null
            if (entry) result[i] = field === "steps" ? entry.steps * 100000 : total(entry)
        }
        return result
    }
    function weekRange(offset) {
        if (!data.updated) return ""
        const monday = new Date(data.updated)
        monday.setDate(monday.getDate() - (monday.getDay() + 6) % 7 - 7 * offset)
        const sunday = new Date(monday)
        sunday.setDate(monday.getDate() + 6)
        return monday.toLocaleDateString(Qt.locale(), "dd/MM") + " – " + sunday.toLocaleDateString(Qt.locale(), "dd/MM")
    }
    readonly property var series: [
        { name: "Claude Code", color: Theme.peach, values: weekValues(cl && cl.days, "tokens", weekOffset) },
        { name: "Codex", color: Theme.green, values: weekValues(cx && cx.days, "tokens", weekOffset) },
        { name: "Antigravity", color: Theme.sky, values: weekValues(ag && ag.days, "steps", weekOffset) }
    ]
    readonly property var labels: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
    readonly property int todayIndex: data.updated && weekOffset === 0 ? (new Date(data.updated).getDay() + 6) % 7 : -1
    readonly property real chartMax: series.reduce((max, s) => Math.max(max, ...s.values), 1)

    IpcHandler {
        target: "ai"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }
    Process {
        id: collector
        command: ["python3", "-I", Quickshell.shellPath("ai-usage.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(text) } catch (e) { /* conserva los datos anteriores */ }
            }
        }
    }
    function refresh() { if (!collector.running) collector.running = true }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    onShownChanged: if (shown) { weekOffset = 0; refresh() }

    component Label: Text {
        color: Theme.subtext0
        font { family: Theme.font; pixelSize: 11 }
    }
    component Stat: ColumnLayout {
        property string title: ""
        property string value: "—"
        property string detail: ""
        property color accent: Theme.text
        width: Math.max(0, (parent.width - 30) / 4)
        height: parent.height
        spacing: 3
        Label { text: title; Layout.fillWidth: true; elide: Text.ElideRight }
        Text { text: value; color: accent; Layout.fillWidth: true; elide: Text.ElideRight; font { family: Theme.font; pixelSize: 15; weight: Font.Bold } }
        Label { text: detail; color: Theme.overlay1; Layout.fillWidth: true; elide: Text.ElideRight }
    }
    component ProviderRow: Rectangle {
        property string name: ""
        property string description: ""
        property color accent: Theme.text
        default property alias stats: statsRow.data
        Layout.fillWidth: true
        implicitHeight: 94
        radius: 12; color: Theme.mantle; border.width: 1; border.color: Theme.surface0
        Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 16 } width: 4; radius: 2; color: accent }
        Column {
            anchors { left: parent.left; leftMargin: 36; verticalCenter: parent.verticalCenter }
            width: 150; spacing: 5
            Text { text: name; color: accent; font { family: Theme.font; pixelSize: 16; weight: Font.Bold } }
            Label { text: description; color: Theme.overlay1; width: parent.width; wrapMode: Text.WordWrap }
        }
        Row { id: statsRow; anchors { left: parent.left; leftMargin: 210; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter } height: 62; spacing: 10 }
    }
    PanelWindow {
        visible: root.shown; color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-ai"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        onVisibleChanged: if (visible) keys.forceActiveFocus()
        Rectangle {
            anchors.fill: parent; color: Theme.crust; opacity: 0.55
            MouseArea { anchors.fill: parent; onClicked: root.shown = false }
        }
        Item {
            id: keys
            anchors.fill: parent; focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) root.shown = false
                else if (event.key === Qt.Key_R) root.refresh()
                else if (event.key === Qt.Key_Left) root.weekOffset = 1
                else if (event.key === Qt.Key_Right) root.weekOffset = 0
                else return
                event.accepted = true
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 1100)
            height: Math.min(parent.height - 48, 790)
            radius: 20; color: Theme.base; border.width: 1; border.color: Theme.surface0
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 3
                        Text { text: "\u{f06a9}  Consumo de IA"; color: Theme.text; font { family: Theme.font; pixelSize: 22; weight: Font.Bold } }
                        Label { text: root.data.updated ? "Actualizado " + root.data.updated.replace("T", " ") : "Cargando datos…"; color: Theme.overlay1 }
                    }
                    Item { Layout.fillWidth: true }
                    IconButton { icon: "\u{f0450}"; size: 32; onClicked: root.refresh() }
                    IconButton { icon: "\u{f0156}"; size: 32; onClicked: root.shown = false }
                }
                Flickable {
                    id: scroll
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: content.implicitHeight
                    clip: true; boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
                    ColumnLayout {
                        id: content
                        width: scroll.width; spacing: 10
                        ProviderRow {
                            name: "Claude Code"; description: "Tokens · incluye caché"; accent: Theme.peach
                            Stat { title: "Hoy"; value: root.todayClaude ? root.fmt(root.total(root.todayClaude)) : "—"; detail: root.todayClaude ? root.todayClaude.msgs + " respuestas" : ""; accent: Theme.peach }
                            Stat { title: "Últimas 5 h"; value: root.cl ? root.fmt(root.total(root.cl.window5h)) : "—"; detail: "tokens procesados"; accent: Theme.peach }
                            Stat { title: "Salida hoy"; value: root.todayClaude ? root.fmt(root.todayClaude.out) : "—"; detail: "tokens generados"; accent: Theme.peach }
                            Stat { title: "Caché leída"; value: root.todayClaude ? root.fmt(root.todayClaude.cr) : "—"; detail: "tokens hoy"; accent: Theme.peach }
                        }
                        ProviderRow {
                            name: "Codex"; description: "Tokens · incluye caché"; accent: Theme.green
                            Stat { title: "Hoy"; value: root.todayCodex ? root.fmt(root.total(root.todayCodex)) : "—"; detail: "tokens procesados"; accent: Theme.green }
                            Stat { title: "Salida hoy"; value: root.todayCodex ? root.fmt(root.todayCodex.out) : "—"; detail: "tokens generados"; accent: Theme.green }
                            Stat { title: root.limitTitle(root.primary, "Ventana principal"); value: root.limitValue(root.primary); detail: root.limitReset(root.primary); accent: Theme.green }
                            Stat { title: root.limitTitle(root.secondary, "Ventana secundaria"); value: root.limitValue(root.secondary); detail: root.limitReset(root.secondary); accent: Theme.green }
                        }
                        ProviderRow {
                            name: "Antigravity"; description: "Actividad · tokens no disponibles"; accent: Theme.sky
                            Stat { title: "Conversaciones"; value: root.ag ? String(root.ag.conversations) : "—"; detail: "guardadas en agy"; accent: Theme.sky }
                            Stat { title: "Pasos · 14 días"; value: root.ag ? root.fmt(root.ag.days.reduce((a, d) => a + d.steps, 0)) : "—"; detail: "acciones del agente"; accent: Theme.sky }
                            Stat { title: "Sesión"; value: root.ag ? (root.ag.loggedIn ? "Activa" : "Sin login") : "—"; detail: "según el último log"; accent: Theme.sky }
                            Stat { title: "Tokens"; value: root.ag && root.ag.tokensAvailable ? "Disponibles" : "Sin datos"; detail: "no registrados por agy"; accent: Theme.sky }
                        }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 275
                            radius: 12; color: Theme.mantle; border.width: 1; border.color: Theme.surface0
                            ColumnLayout {
                                anchors { fill: parent; margins: 16 }
                                spacing: 9
                                RowLayout {
                                    Layout.fillWidth: true
                                    IconButton { icon: "\u{f0141}"; size: 24; iconSize: 14; enabled: root.weekOffset === 0; opacity: enabled ? 1 : 0.35; onClicked: root.weekOffset = 1 }
                                    IconButton { icon: "\u{f0142}"; size: 24; iconSize: 14; enabled: root.weekOffset === 1; opacity: enabled ? 1 : 0.35; onClicked: root.weekOffset = 0 }
                                    Text {
                                        text: "Actividad diaria · " + (root.weekOffset === 0 ? "semana actual" : "semana anterior") + (root.data.updated ? " (" + root.weekRange(root.weekOffset) + ")" : "")
                                        color: Theme.text; font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Repeater {
                                        model: root.series
                                        RowLayout {
                                            required property var modelData
                                            spacing: 5
                                            Rectangle { width: 8; height: 8; radius: 2; color: modelData.color }
                                            Label { text: modelData.name }
                                        }
                                    }
                                }
                                Label { text: "Escala común en tokens · Antigravity estimado: 100K tokens por paso · máximo " + root.fmt(root.chartMax); color: Theme.overlay1; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Item {
                                    id: chart
                                    property string hoverText: ""
                                    property real hoverX: 0
                                    property real hoverY: 0
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    Row {
                                        id: groups
                                        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: axis.top; bottomMargin: 6 }
                                        spacing: 5
                                        Repeater {
                                            model: root.labels.length
                                            Item {
                                                required property int index
                                                width: (groups.width - 5 * (root.labels.length - 1)) / Math.max(1, root.labels.length)
                                                height: groups.height
                                                Row {
                                                    anchors { fill: parent; leftMargin: 2; rightMargin: 2 }
                                                    spacing: 2
                                                    Repeater {
                                                        model: root.series
                                                        Item {
                                                            required property var modelData
                                                            readonly property int dayIndex: parent.parent.index
                                                            readonly property real v: modelData.values[dayIndex] || 0
                                                            readonly property real maxV: root.chartMax
                                                            width: (parent.width - 4) / 3; height: parent.height
                                                            Rectangle { anchors.fill: parent; radius: 3; color: Theme.surface0; opacity: 0.45 }
                                                            Rectangle {
                                                                anchors.bottom: parent.bottom; width: parent.width
                                                                height: v > 0 ? Math.max(3, parent.height * v / maxV) : 0
                                                                radius: 3; color: modelData.color; opacity: dayIndex === root.todayIndex ? 1 : 0.65
                                                            }
                                                            HoverHandler {
                                                                onHoveredChanged: {
                                                                    if (hovered) {
                                                                        const p = parent.mapToItem(chart, parent.width / 2, parent.height - Math.max(3, parent.height * parent.v / parent.maxV))
                                                                        chart.hoverX = p.x
                                                                        chart.hoverY = p.y
                                                                        chart.hoverText = modelData.name + ": " + root.fmt(parent.v) + (modelData.name === "Antigravity" ? " tokens estimados" : " tokens")
                                                                    } else chart.hoverText = ""
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Row {
                                        id: axis
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                        height: 14; spacing: 5
                                        Repeater {
                                            model: root.labels
                                            Text {
                                                required property int index; required property string modelData
                                                width: (axis.width - 5 * (root.labels.length - 1)) / Math.max(1, root.labels.length)
                                                text: modelData; horizontalAlignment: Text.AlignHCenter; color: Theme.overlay0
                                                font { family: Theme.font; pixelSize: 10 }
                                            }
                                        }
                                    }
                                    Rectangle {
                                        z: 100; visible: chart.hoverText !== ""
                                        width: tip.implicitWidth + 16; height: 24; radius: 6
                                        x: Math.max(0, Math.min(chart.width - width, chart.hoverX - width / 2))
                                        y: Math.max(0, chart.hoverY - height - 5)
                                        color: Theme.crust; border.width: 1; border.color: Theme.surface1
                                        Text { id: tip; anchors.centerIn: parent; text: chart.hoverText; color: Theme.text; font { family: Theme.font; pixelSize: 11 } }
                                    }
                                }
                            }
                        }
                        Label {
                            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.overlay1
                            text: (root.cx && root.cx.limitsUpdated ? "Límites de Codex registrados: " + root.cx.limitsUpdated.replace("T", " ") + ". " : "") + "Antigravity agrupa los pasos por la última modificación de cada conversación."
                        }
                    }
                }
            }
        }
    }
}
