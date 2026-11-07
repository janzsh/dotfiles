// Indicador de wifi para la barra (nmcli). Hover de 2 s / clic abre un panel
// con la red actual, la señal y un botón para apagar/encender la radio.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    property bool radioOn: true
    property string ssid: ""
    property int signal: 0
    readonly property bool connected: ssid !== ""

    implicitWidth: 34
    implicitHeight: 36
    popupWidth: 240

    readonly property string icon: !radioOn ? "󰤮"
        : !connected ? "󰤭"
        : signal > 75 ? "󰤨" : signal > 50 ? "󰤥" : signal > 25 ? "󰤢" : "󰤟"

    function refresh() { poll.running = true }

    Process {
        id: poll
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                root.radioOn = lines[0] === "enabled"
                const m = lines.length > 1 ? lines[1].match(/^yes:(.*):(\d+)$/) : null
                root.ssid = m ? m[1] : ""
                root.signal = m ? parseInt(m[2]) : 0
            }
        }
    }
    Process { id: toggle; onRunningChanged: if (!running) root.refresh() }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.hovered ? Theme.surface0 : "transparent"
    }
    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.connected ? Theme.mauve : Theme.overlay0
        font { family: Theme.font; pixelSize: Theme.iconSize }
    }

    popup: Component {
        ColumnLayout {
            spacing: 10

            Text {
                text: !root.radioOn ? "Wi-Fi apagado" : root.connected ? root.ssid : "Sin conexión"
                color: Theme.text
                font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
            }
            Text {
                visible: root.connected
                text: "Señal " + root.signal + "%"
                color: Theme.subtext0
                font { family: Theme.font; pixelSize: 12 }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 10
                color: ma.containsMouse ? Theme.surface1 : Theme.surface0
                Text {
                    anchors.centerIn: parent
                    text: root.radioOn ? "Apagar Wi-Fi" : "Encender Wi-Fi"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 12; weight: Font.Bold }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        toggle.command = ["nmcli", "radio", "wifi", root.radioOn ? "off" : "on"]
                        toggle.running = true
                    }
                }
            }
        }
    }
}
