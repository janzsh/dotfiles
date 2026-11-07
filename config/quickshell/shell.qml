// La API de Quickshell cambia entre versiones — revisa quickshell.org/docs
// contra la versión instalada antes de ampliar esto.
//
// Lee ~/.cache/wm-state.json, escrito en vivo por
// config/sway/scripts/wm-state-bridge.sh (swaymsg subscribe + jq).

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Launcher { id: launcher }
    PowerMenu { id: powerMenu }
    Lock { id: lockScreen }
    Clipboard { id: clipboard }
    OSD { id: osd }
    Ringer { id: ringer }
    Pomodoro { id: pomodoro; ringer: ringer }
    Alarms { id: alarms; ringer: ringer }
    Countdown { id: countdown; ringer: ringer }
    Stopwatch { id: stopwatch }
    AiUsage { id: aiUsage }
    Dock { apps: stateFile.state.apps || [] }
    Switcher { windows: stateFile.state.windows || [] }

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/wm-state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: parseState()

        property var state: ({ groups: [], layout: "" })

        // Workspaces a mostrar: "activos" = enfocado, con ventanas o urgente.
        // Con más de 4 activos solo esos; si no, los 4 primeros más los activos.
        readonly property var visibleGroups: {
            const g = state.groups || []
            const act = g.map(w => w.focused || w.open || w.urgent)
            const n = act.filter(a => a).length
            return g.filter((w, i) => act[i] || (n <= 4 && i < 4))
        }

        function parseState() {
            try {
                state = JSON.parse(text())
            } catch (e) {
                state = { groups: [], layout: "" }
            }
        }
    }

    PanelWindow {
        id: bar
        WlrLayershell.namespace: "qs-bar"   // swayfx lo usa en layer_effects
        anchors { top: true; left: true; right: true }
        implicitHeight: 48
        color: "transparent"   // la barra son "islas" flotantes con gap

        // Fondo común de cada isla: translúcido, borde sutil.
        component Island: Rectangle {
            height: 36
            radius: 12
            color: Qt.alpha(Theme.crust, 0.78)
            border.width: 1
            border.color: Qt.alpha(Theme.surface1, 0.55)
        }

        // Izquierda: menú de Nix, workspaces (enfocado y activos) y reproductor
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Island {
                width: 38
                NixMenu {
                    anchors.centerIn: parent
                    launcherRef: launcher
                }
            }

            Island {
                width: wsRow.width + 24

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: stateFile.visibleGroups
                        Rectangle {
                            width: modelData.focused ? 34 : 22
                            height: 22
                            radius: 7
                            color: modelData.focused ? Theme.mauve
                                 : modelData.urgent ? Theme.red
                                 : modelData.open ? Theme.mauvePastel : Theme.surface0
                            Behavior on width { NumberAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: modelData.focused || modelData.urgent ? Theme.crust
                                     : modelData.open ? Theme.crust : Theme.overlay0
                                font { family: Theme.font; pixelSize: 11; weight: Font.Bold }
                            }
                            // Clic: ir a ese workspace (el "0" es el 10).
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached([Quickshell.shellDir + "/wmctl.sh", "workspace",
                                    modelData.name === "0" ? "10" : modelData.name])
                            }
                        }
                    }
                }
            }
            // Reproductor multimedia (solo visible si hay un player MPRIS)
            Island {
                visible: media.hasPlayer
                width: media.implicitWidth
                MediaWidget { id: media; anchors.fill: parent }
            }
        }

        // Derecha: CPU/RAM, calendario, audio + wifi + bluetooth, IA (tokens), batería y energía, cada uno en su isla
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Island {
                width: sysStats.implicitWidth
                CpuRamWidget { id: sysStats; anchors.fill: parent }
            }
            Island {
                width: calendar.implicitWidth
                CalendarWidget { id: calendar; anchors.fill: parent; pomo: pomodoro; alarms: alarms; countdown: countdown; stopwatch: stopwatch }
            }
            Island {
                width: vol.implicitWidth + wifi.implicitWidth + bt.implicitWidth + 8
                Row {
                    anchors.centerIn: parent
                    spacing: 0
                    VolumeWidget { id: vol }
                    WifiWidget { id: wifi }
                    BluetoothWidget { id: bt }
                }
            }
            Island {
                width: aiBtn.implicitWidth
                AiWidget { id: aiBtn; anchors.fill: parent; ai: aiUsage }
            }
            Island {
                width: battery.implicitWidth
                BatteryWidget { id: battery; anchors.fill: parent }
            }
            Island {
                width: 38
                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 9
                    color: powerArea.containsMouse || powerMenu.shown ? Theme.surface0 : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "\u{f0425}"
                        color: Theme.red
                        font { family: Theme.font; pixelSize: Theme.iconSize }
                    }
                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: powerMenu.shown = !powerMenu.shown
                    }
                }
            }
        }
    }
}
