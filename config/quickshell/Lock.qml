// Pantalla de bloqueo propia (ext-session-lock + PAM), con el mismo estilo que
// el lanzador: fondo difuminado, reloj, tarjeta de usuario y botones de sesión.
//
//   qs ipc call lock lock      bloquear (mod+shift+l)
//   qs ipc call lock suspend   bloquear y suspender en RAM cuando el bloqueo ya es seguro
//
// Si Quickshell muere con la pantalla bloqueada, sway la mantiene bloqueada
// por diseño. Recuperación: ctrl+alt+F3, entrar y ejecutar `pkill quickshell;
// WAYLAND_DISPLAY=wayland-1 quickshell` (o `pkill sway` para cerrar la sesión).

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Scope {
    id: root

    property bool pendingSuspend: false
    property bool failed: false
    property bool busy: false
    readonly property alias locked: lock.locked

    IpcHandler {
        target: "lock"
        function lock(): void { lock.locked = true }
        function unlock(): void { lock.locked = false }
        function suspend(): void { root.pendingSuspend = true; lock.locked = true }
    }

    function submit(pw) {
        if (busy || pw === "") return
        failed = false
        busy = true
        pam.password = pw
        pam.start()
    }

    WlSessionLock {
        id: lock
        locked: false
        onSecureChanged: if (secure && root.pendingSuspend) {
            root.pendingSuspend = false
            Quickshell.execDetached(["systemctl", "suspend"])
        }
        onLockedChanged: if (!locked) { root.failed = false; root.busy = false }

        WlSessionLockSurface {
            id: surface
            color: Theme.crust

            // Fondo: wallpaper difuminado y atenuado.
            Image {
                id: wall
                anchors.fill: parent
                source: "file://" + Quickshell.env("HOME") + "/Pictures/evernight.jpg"
                fillMode: Image.PreserveAspectCrop
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                visible: wall.status === Image.Ready
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                brightness: -0.15
            }
            Rectangle { anchors.fill: parent; color: Theme.crust; opacity: 0.45 }

            // Reloj
            Column {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.12 }
                spacing: 4
                Text {
                    id: clock
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 84; weight: Font.Light }
                    text: Qt.formatTime(tick.now, "HH:mm")
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 16 }
                    text: Qt.locale("es_CO").toString(tick.now, "dddd, d 'de' MMMM")
                }
            }
            QtObject { id: tick; property date now: new Date() }
            Timer { running: true; repeat: true; interval: 1000; onTriggered: tick.now = new Date() }

            // Tarjeta de sesión
            Rectangle {
                id: card
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 70
                width: 340
                height: cardCol.implicitHeight + 44
                radius: 16
                color: Qt.alpha(Theme.base, 0.88)
                border.width: 1
                border.color: Theme.surface0

                // Sacudida al fallar.
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -10; duration: 40 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 10; duration: 70 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40 }
                }
                Connections { target: root; function onFailedChanged() { if (root.failed) shake.restart() } }

                ColumnLayout {
                    id: cardCol
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 22 }
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 64; implicitHeight: 64; radius: 32
                        color: Theme.surface0
                        border.width: 2
                        border.color: root.failed ? Theme.red : Theme.mauve
                        Text {
                            anchors.centerIn: parent
                            text: Quickshell.env("USER").charAt(0).toUpperCase()
                            color: Theme.mauve
                            font { family: Theme.font; pixelSize: 28; weight: Font.Bold }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Quickshell.env("USER")
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 16; weight: Font.Medium }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 11
                        color: Theme.mantle
                        border.width: 1
                        border.color: root.failed ? Qt.alpha(Theme.red, 0.7)
                                    : pass.activeFocus ? Qt.alpha(Theme.mauve, 0.45) : "transparent"

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            spacing: 10
                            Text {
                                text: "\u{f033e}"
                                color: root.failed ? Theme.red : Theme.mauve
                                font { family: Theme.font; pixelSize: 15 }
                            }
                            TextInput {
                                id: pass
                                Layout.fillWidth: true
                                focus: true
                                echoMode: TextInput.Password
                                passwordCharacter: "•"
                                enabled: !root.busy
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 14 }
                                clip: true
                                onTextChanged: root.failed = false
                                onAccepted: { root.submit(text); text = "" }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !pass.text
                                    text: root.busy ? "Verificando…" : "Contraseña"
                                    color: Theme.overlay0
                                    font: pass.font
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.failed
                        text: "Contraseña incorrecta"
                        color: Theme.red
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
            }

            // Botones de sesión (como un lanzador de sesiones)
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
                spacing: 12
                Repeater {
                    model: [
                        { icon: "\u{f04b2}", label: "Suspender", color: Theme.blue,  cmd: ["qs", "ipc", "call", "lock", "suspend"] },
                        { icon: "\u{f0709}", label: "Reiniciar", color: Theme.peach, cmd: ["systemctl", "reboot"] },
                        { icon: "\u{f0425}", label: "Apagar",    color: Theme.red,   cmd: ["systemctl", "poweroff"] }
                    ]
                    Rectangle {
                        id: sb
                        required property var modelData
                        width: 48; height: 48; radius: 12
                        color: sbArea.containsMouse ? Theme.surface0 : Qt.alpha(Theme.base, 0.8)
                        border.width: 1
                        border.color: sbArea.containsMouse ? Qt.alpha(modelData.color, 0.6) : Theme.surface0
                        Text {
                            anchors.centerIn: parent
                            text: sb.modelData.icon
                            color: sb.modelData.color
                            font { family: Theme.font; pixelSize: 20 }
                        }
                        MouseArea {
                            id: sbArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(sb.modelData.cmd)
                        }
                    }
                }
            }

            Component.onCompleted: pass.forceActiveFocus()
        }
    }

    PamContext {
        id: pam
        config: "swaylock"   // servicio PAM que registra programs.sway
        property string password: ""

        onPamMessage: {
            if (responseRequired) respond(password)
        }
        onCompleted: result => {
            root.busy = false
            pam.password = ""
            if (result === PamResult.Success) lock.locked = false
            else root.failed = true
        }
    }
}
