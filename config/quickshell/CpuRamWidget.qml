// CPU y RAM para la barra. Lee /proc/stat y /proc/meminfo cada 2 s. Con hover
// (ver HoverPopup) abre un panel con detalle: carga, núcleos, memoria, swap
// y los procesos que más consumen.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    property real cpu: 0                 // 0..100
    property var cores: []               // % por núcleo
    property var prev: ({})              // contadores previos por línea cpu*
    property real memTotal: 0            // KiB
    property real memAvail: 0
    property real memCached: 0
    property real swapTotal: 0
    property real swapFree: 0
    property string load: "—"
    property var procs: []

    readonly property real memUsed: memTotal - memAvail
    readonly property real ram: memTotal > 0 ? memUsed / memTotal * 100 : 0

    function level(p) { return p >= 85 ? Theme.red : p >= 60 ? Theme.yellow : Theme.mauve }
    function gib(kib) { return (kib / 1048576).toFixed(1) + " GiB" }

    function parseStat(t) {
        const next = {}, pcts = []
        let total = 0
        for (const line of t.split("\n")) {
            if (!line.startsWith("cpu")) continue
            const f = line.trim().split(/\s+/)
            const name = f[0]
            const v = f.slice(1).map(Number)
            const idle = v[3] + (v[4] || 0)
            const sum = v.slice(0, 8).reduce((a, b) => a + b, 0)
            next[name] = [idle, sum]
            const p = prev[name]
            const pct = p && sum > p[1] ? (1 - (idle - p[0]) / (sum - p[1])) * 100 : 0
            if (name === "cpu") total = pct; else pcts.push(pct)
        }
        prev = next
        cpu = total
        cores = pcts
    }

    function parseMem(t) {
        const m = {}
        for (const line of t.split("\n")) {
            const f = line.split(/\s+/)
            if (f.length > 1) m[f[0]] = Number(f[1])
        }
        memTotal = m["MemTotal:"] || 0
        memAvail = m["MemAvailable:"] || 0
        memCached = (m["Cached:"] || 0) + (m["SReclaimable:"] || 0)
        swapTotal = m["SwapTotal:"] || 0
        swapFree = m["SwapFree:"] || 0
    }

    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }
    FileView { id: loadFile; path: "/proc/loadavg" }

    Process {
        id: psProc
        command: ["sh", "-c", "ps -eo comm=,pcpu=,rss= --sort=-pcpu | head -5"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.procs = text.trim().split("\n").filter(l => l).map(l => {
                    const f = l.trim().split(/\s+/)
                    const n = f.length
                    return { name: f.slice(0, n - 2).join(" "), cpu: Number(f[n - 2]), rss: Number(f[n - 1]) }
                })
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload(); memFile.reload(); loadFile.reload()
            root.parseStat(statFile.text())
            root.parseMem(memFile.text())
            root.load = loadFile.text().split(" ").slice(0, 3).join("  ")
            if (root.open && !psProc.running) psProc.running = true
        }
    }

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 36
    popupWidth: 320

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.hovered ? Theme.surface0 : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: [
                { label: "CPU", value: root.cpu },
                { label: "RAM", value: root.ram }
            ]
            Row {
                required property var modelData
                required property int index
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {   // separador entre CPU y RAM
                    visible: index > 0
                    width: 1
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surface2
                }
                Row {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: modelData.label
                        color: root.level(modelData.value)
                        font { family: Theme.font; pixelSize: 11; weight: Font.Bold }
                        anchors.baseline: pct.baseline
                    }
                    Text {
                        id: pct
                        width: 34
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(modelData.value) + "%"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
                    }
                }
            }
        }
    }

    component Meter: Rectangle {
        property real value: 0
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: Theme.surface0
        Rectangle {
            width: parent.width * Math.min(1, parent.value / 100)
            height: parent.height
            radius: 3
            color: root.level(parent.value)
            Behavior on width { NumberAnimation { duration: 200 } }
        }
    }

    component KV: RowLayout {
        property string k
        property string v
        Layout.fillWidth: true
        Text { text: parent.k; color: Theme.subtext0; font { family: Theme.font; pixelSize: 12 } }
        Item { Layout.fillWidth: true }
        Text { text: parent.v; color: Theme.text; font { family: Theme.font; pixelSize: 12 } }
    }

    popup: Component {
        ColumnLayout {
            spacing: 8
            implicitHeight: childrenRect.height

            // CPU
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "CPU  " + Math.round(root.cpu) + "%"
                    color: root.level(root.cpu)
                    font { family: Theme.font; pixelSize: 20; weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.cores.length + " núcleos"
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 12 }
                }
            }
            Meter { value: root.cpu }
            KV { k: "Carga (1/5/15 min)"; v: root.load }

            // Barras por núcleo
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 3
                Repeater {
                    model: root.cores
                    Item {
                        required property real modelData
                        width: Math.max(4, (parent.width - 3 * (root.cores.length - 1)) / Math.max(1, root.cores.length))
                        height: 34
                        Rectangle { anchors.fill: parent; radius: 2; color: Theme.surface0 }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, parent.height * Math.min(1, modelData / 100))
                            radius: 2
                            color: root.level(modelData)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: Theme.surface1 }

            // RAM
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "RAM  " + Math.round(root.ram) + "%"
                    color: root.level(root.ram)
                    font { family: Theme.font; pixelSize: 20; weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.gib(root.memUsed) + " / " + root.gib(root.memTotal)
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 12 }
                }
            }
            Meter { value: root.ram }
            KV { k: "Disponible"; v: root.gib(root.memAvail) }
            KV { k: "Caché"; v: root.gib(root.memCached) }
            KV {
                k: "Swap"
                v: root.swapTotal > 0
                   ? root.gib(root.swapTotal - root.swapFree) + " / " + root.gib(root.swapTotal)
                   : "sin swap"
            }

            Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: Theme.surface1 }

            Text {
                text: "Procesos principales"
                color: Theme.subtext0
                font { family: Theme.font; pixelSize: 11 }
            }
            Repeater {
                model: root.procs
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Text {
                        text: modelData.name
                        color: Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        font { family: Theme.font; pixelSize: 12 }
                    }
                    Text {
                        text: modelData.cpu.toFixed(1) + "%"
                        color: root.level(modelData.cpu)
                        font { family: Theme.font; pixelSize: 12 }
                    }
                    Text {
                        text: (modelData.rss / 1024).toFixed(0) + " MiB"
                        color: Theme.overlay1
                        Layout.preferredWidth: 70
                        horizontalAlignment: Text.AlignRight
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
            }
        }
    }
}
