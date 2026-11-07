// OSD de volumen/brillo/micrófono: aparece abajo al centro, anima entrada,
// salida y la barra de nivel. Lo dispara config/sway/scripts/osd.sh por IPC:
//   qs ipc call osd show <volume|brightness|mic> <0-100> <muted>

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property bool shown: false
    property string kind: "volume"
    property int value: 0
    property bool muted: false

    IpcHandler {
        target: "osd"
        function popup(kind: string, value: int, muted: bool): void {
            root.kind = kind
            root.value = value
            root.muted = muted
            root.shown = true
            hideTimer.restart()
        }
    }

    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    readonly property color accent: muted ? Theme.red
        : kind === "brightness" ? Theme.yellow
        : kind === "mic" ? Theme.ok : Theme.mauve

    readonly property string icon: {
        if (kind === "brightness") return value < 35 ? "\u{f00de}" : value < 70 ? "\u{f00df}" : "\u{f00e0}"
        if (kind === "mic") return muted ? "\u{f036d}" : "\u{f036c}"
        if (muted || value === 0) return "\u{f0581}"
        return value < 35 ? "\u{f057f}" : value < 70 ? "\u{f0580}" : "\u{f057e}"
    }

    PanelWindow {
        id: win
        visible: card.opacity > 0
        color: "transparent"
        anchors { bottom: true }
        margins.bottom: 70
        implicitWidth: 300
        implicitHeight: 64
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-osd"
        mask: Region {}   // no captura el ratón

        Rectangle {
            id: card
            width: 280
            height: 52
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 16
            color: Qt.alpha(Theme.crust, 0.88)
            border.width: 1
            border.color: Qt.alpha(Theme.surface1, 0.6)

            opacity: root.shown ? 1 : 0
            y: root.shown ? 6 : 26
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Text {
                id: ico
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                text: root.icon
                color: root.accent
                font { family: Theme.font; pixelSize: 22 }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Rectangle {
                id: track
                anchors {
                    left: ico.right; leftMargin: 14
                    right: pct.left; rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                height: 8
                radius: 4
                color: Theme.surface0

                Rectangle {
                    height: parent.height
                    radius: 4
                    color: root.accent
                    width: parent.width * Math.min(root.muted ? 0 : root.value, root.kind === "volume" ? 125 : 100) / (root.kind === "volume" ? 125 : 100)
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Tramo por encima de 100% (solo volumen), en un tono más oscuro
                Rectangle {
                    visible: root.kind === "volume" && !root.muted && root.value > 100
                    x: parent.width * 100 / 125
                    height: parent.height
                    radius: 4
                    color: Qt.darker(root.accent, 1.7)
                    width: parent.width * (Math.min(root.value, 125) - 100) / 125
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                id: pct
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                width: 36
                horizontalAlignment: Text.AlignRight
                text: root.kind === "mic" ? (root.muted ? "off" : "on") : root.muted ? "mute" : root.value + "%"
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
            }
        }
    }
}
