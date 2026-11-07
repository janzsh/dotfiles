// Menú de energía: bloquear, suspender (RAM), cerrar sesión, reiniciar, apagar.
// Se abre desde el botón de la barra o por IPC:  qs ipc call power toggle
// Bloquear/suspender los hace Lock.qml.
// Teclas: l bloquear · s suspender · e cerrar sesión · r reiniciar · p apagar · Esc cerrar

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool shown: false

    IpcHandler {
        target: "power"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }

    readonly property var actions: [
        { key: Qt.Key_L, hint: "L", label: "Bloquear",  icon: "\u{f033e}", color: Theme.sky,   cmd: ["qs", "ipc", "call", "lock", "lock"] },
        { key: Qt.Key_S, hint: "S", label: "Suspender", icon: "\u{f04b2}", color: Theme.blue,  cmd: ["qs", "ipc", "call", "lock", "suspend"] },
        { key: Qt.Key_E, hint: "E", label: "Salir",     icon: "\u{f0343}", color: Theme.yellow, cmd: [Quickshell.shellDir + "/wmctl.sh", "exit"] },
        { key: Qt.Key_R, hint: "R", label: "Reiniciar", icon: "\u{f0709}", color: Theme.peach, cmd: ["systemctl", "reboot"] },
        { key: Qt.Key_P, hint: "P", label: "Apagar",    icon: "\u{f0425}", color: Theme.red,   cmd: ["systemctl", "poweroff"] }
    ]

    function run(action) {
        root.shown = false
        Quickshell.execDetached(action.cmd)
    }

    PanelWindow {
        visible: root.shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-power"
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
                if (event.key === Qt.Key_Escape) {
                    root.shown = false
                    event.accepted = true
                    return
                }
                for (const a of root.actions) {
                    if (event.key === a.key) { root.run(a); event.accepted = true; return }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: buttons.implicitWidth + 32
            height: buttons.implicitHeight + 32
            radius: 16
            color: Theme.base
            border.width: 1
            border.color: Theme.surface0

            MouseArea { anchors.fill: parent }

            Row {
                id: buttons
                anchors.centerIn: parent
                spacing: 10

                Repeater {
                    model: root.actions
                    Rectangle {
                        id: btn
                        required property var modelData
                        width: 96; height: 96
                        radius: 12
                        color: area.containsMouse ? Theme.surface0 : Theme.mantle
                        border.width: 1
                        border.color: area.containsMouse ? Qt.alpha(modelData.color, 0.6) : "transparent"

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.icon
                                color: btn.modelData.color
                                font { family: Theme.font; pixelSize: 30 }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.label
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 12 }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.hint
                                color: Theme.overlay0
                                font { family: Theme.font; pixelSize: 10 }
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(btn.modelData)
                        }
                    }
                }
            }
        }
    }
}
