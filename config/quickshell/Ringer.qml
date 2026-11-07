// Aviso a pantalla completa cuando suena una alarma o termina un temporizador:
// repite el sonido en bucle (máx. 60 s) hasta pulsar Detener, Esc, Enter o
// Espacio. Con canSnooze añade "Posponer 5 min". Lo usan Alarms y Countdown.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool shown: false
    property string title: ""
    property string detail: ""
    property string sound: ""
    property bool canSnooze: false
    property var snoozeFn: null
    property color tint: "transparent"   // color propio (p. ej. el de la fase del pomodoro)
    readonly property color accent: tint.a > 0 ? tint : canSnooze ? Theme.yellow : Theme.ok

    function ring(title, detail, sound, canSnooze, snoozeFn, tint) {
        root.tint = tint || "transparent"
        root.title = title
        root.detail = detail
        root.sound = sound
        root.canSnooze = canSnooze
        root.snoozeFn = snoozeFn || null
        root.shown = true
        autoStop.restart()
        syncSound()
    }
    function stop() { shown = false; autoStop.stop(); syncSound() }
    function snooze() { if (snoozeFn) snoozeFn(); stop() }

    // Bucle: al terminar el archivo se relanza mientras siga sonando el aviso.
    function syncSound() {
        if (shown && sound !== "") {
            player.command = ["pw-play", sound]
            player.running = true
        } else {
            player.running = false
        }
    }
    Process { id: player; onExited: root.syncSound() }

    IpcHandler {
        target: "ringer"
        function stop(): void { root.stop() }
    }
    Timer { id: autoStop; interval: 60000; onTriggered: root.stop() }

    PanelWindow {
        visible: root.shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-ringer"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
            opacity: 0.6
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return
                    || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.stop()
                    event.accepted = true
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 380
            height: card.implicitHeight + 56
            radius: 20
            color: Theme.base
            border.width: 1
            border.color: Qt.alpha(root.accent, 0.5)

            ColumnLayout {
                id: card
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
                spacing: 14

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.canSnooze ? "\u{f0020}" : "\u{f13ab}"
                    color: root.accent
                    font { family: Theme.font; pixelSize: 44 }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.title
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 20; weight: Font.Bold }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.detail
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 14 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 10
                    Rectangle {
                        visible: root.canSnooze
                        Layout.fillWidth: true
                        height: 40; radius: 12
                        color: snoozeMa.containsMouse ? Theme.surface1 : Theme.surface0
                        Text {
                            anchors.centerIn: parent
                            text: "Posponer 5 min"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13 }
                        }
                        MouseArea { id: snoozeMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.snooze() }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40; radius: 12
                        color: stopMa.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent
                        Text {
                            anchors.centerIn: parent
                            text: "Detener"
                            color: Theme.crust
                            font { family: Theme.font; pixelSize: 13; weight: Font.Bold }
                        }
                        MouseArea { id: stopMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.stop() }
                    }
                }
            }
        }
    }
}
