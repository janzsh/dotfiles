// Control de audio para la barra (PipeWire): icono del volumen de salida; la
// rueda sobre él sube/baja el volumen y el clic (o 2 s de hover) abre un panel
// con volumen y mute de salida y entrada, y listas para elegir el dispositivo
// de salida (altavoces, auriculares…) y de entrada (micrófonos).

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    implicitWidth: 34
    implicitHeight: 36
    popupWidth: 320

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Dispositivos reales (no streams de aplicaciones).
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    // Sin tracker los nodos no exponen volumen/mute.
    PwObjectTracker { objects: root.sinks.concat(root.sources) }

    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted

    function label(n) { return n.nickname || n.description || n.name }
    function setVol(node, v) {
        if (node && node.audio) {
            node.audio.muted = false
            node.audio.volume = Math.max(0, Math.min(1, v))
        }
    }
    function sinkIcon(v, m) {
        if (m || v === 0) return "\u{f0581}"
        return v < 0.35 ? "\u{f057f}" : v < 0.7 ? "\u{f0580}" : "\u{f057e}"
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.hovered ? Theme.surface0 : "transparent"
    }
    Text {
        anchors.centerIn: parent
        text: root.sinkIcon(root.vol, root.muted)
        color: root.muted ? Theme.overlay0 : Theme.mauve
        font { family: Theme.font; pixelSize: Theme.iconSize }
    }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.setVol(root.sink, root.vol + (event.angleDelta.y > 0 ? 0.05 : -0.05))
    }

    // Fila de volumen: botón mute + barra arrastrable + porcentaje.
    component LevelRow: RowLayout {
        id: lr
        property var node
        property bool isInput: false
        readonly property real v: node && node.audio ? node.audio.volume : 0
        readonly property bool m: !node || !node.audio || node.audio.muted
        spacing: 10
        Layout.fillWidth: true

        Rectangle {
            width: 28; height: 28; radius: 8
            color: muteMa.containsMouse ? Theme.surface1 : Theme.surface0
            Text {
                anchors.centerIn: parent
                text: lr.isInput ? (lr.m ? "\u{f036d}" : "\u{f036c}") : root.sinkIcon(lr.v, lr.m)
                color: lr.m ? Theme.red : Theme.text
                font { family: Theme.font; pixelSize: 15 }
            }
            MouseArea {
                id: muteMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: lr.node !== null && lr.node !== undefined
                onClicked: lr.node.audio.muted = !lr.node.audio.muted
            }
        }
        Item {
            Layout.fillWidth: true
            height: 20
            Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 6; radius: 3
                color: Theme.surface1
                Rectangle {
                    width: parent.width * Math.min(1, lr.v)
                    height: parent.height; radius: 3
                    color: lr.m ? Theme.overlay0 : lr.isInput ? Theme.ok : Theme.mauve
                }
            }
            Rectangle {
                x: Math.min(1, lr.v) * (parent.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 14; radius: 7
                color: Theme.text
            }
            MouseArea {
                anchors.fill: parent
                function set(mx) { root.setVol(lr.node, mx / width) }
                onPressed: mouse => set(mouse.x)
                onPositionChanged: mouse => { if (pressed) set(mouse.x) }
            }
        }
        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round(Math.min(1, lr.v) * 100) + "%"
            color: Theme.subtext0
            font { family: Theme.font; pixelSize: 12 }
        }
    }

    // Lista de dispositivos; el clic fija el predeterminado.
    component DeviceList: ColumnLayout {
        id: dl
        property var devices: []
        property var current
        property bool isInput: false
        spacing: 3
        Layout.fillWidth: true
        Repeater {
            model: dl.devices
            Rectangle {
                required property var modelData
                readonly property bool active: dl.current !== null && dl.current !== undefined && modelData.id === dl.current.id
                Layout.fillWidth: true
                height: 30
                radius: 9
                color: active ? Qt.alpha(Theme.mauve, 0.2) : devMa.containsMouse ? Theme.surface0 : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8
                    Text {
                        text: active ? "\u{f012c}" : "\u{f0765}"
                        color: active ? Theme.mauve : Theme.overlay0
                        font { family: Theme.font; pixelSize: 13 }
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.label(modelData)
                        color: active ? Theme.text : Theme.subtext0
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
                MouseArea {
                    id: devMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (dl.isInput) Pipewire.preferredDefaultAudioSource = modelData
                        else Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }
        }
    }

    popup: Component {
        ColumnLayout {
            spacing: 10

            Text {
                text: "Salida"
                color: Theme.text
                font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
            }
            LevelRow { node: root.sink }
            DeviceList { devices: root.sinks; current: root.sink }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.surface2, 0.5) }

            Text {
                text: "Entrada"
                color: Theme.text
                font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
            }
            LevelRow { node: root.source; isInput: true }
            DeviceList { devices: root.sources; current: root.source; isInput: true }
        }
    }
}
