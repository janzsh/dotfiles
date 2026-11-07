// Pantalla de inicio de sesión (greetd + Quickshell). Corre como usuario
// `greeter` dentro de cage (ver nix/modules/desktop/greetd.nix).
//
// Variables de entorno (las pone el módulo de Nix):
//   GREETER_CONFIG  JSON generado: { user, displayName, sessions: [{ name, exec, desktopNames }] }
//   GREETER_STATE   archivo donde se recuerda la última sesión elegida
//
// Sin greetd (Greetd.available == false) arranca en modo demo: la contraseña
// es "demo" y no lanza nada. Se prueba con:  qs -p ~/dotfiles/config/greeter
// (necesita Theme.qml y LoadingRing.qml al lado: el módulo de Nix los copia).

import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

ShellRoot {
    id: root

    property string user: "janz"
    property string displayName: "Usuario"
    property var sessions: [{ name: "Hyprland", exec: "start-hyprland", desktopNames: "Hyprland" }]
    property int sessionIdx: 0
    property string lastSession: ""

    property bool busy: false
    property bool failed: false
    property bool starting: false
    readonly property bool demo: !Greetd.available
    readonly property var session: sessions[Math.min(sessionIdx, sessions.length - 1)]
    property string password: ""

    function cleanName(n) { return n.replace(/ \(uwsm-managed\)/, "") }

    function applyConfig(txt) {
        try {
            const c = JSON.parse(txt)
            if (c.user) user = c.user
            if (c.displayName) displayName = c.displayName
            if (c.sessions && c.sessions.length) sessions = c.sessions
            pickLast()
        } catch (e) { /* config ilegible: se conservan los valores por defecto */ }
    }

    function pickLast() {
        const i = sessions.findIndex(s => s.name === lastSession)
        if (i >= 0) sessionIdx = i
    }

    function cycle(d) { sessionIdx = (sessionIdx + d + sessions.length) % sessions.length }

    function submit() {
        if (busy || starting || password === "") return
        failed = false
        busy = true
        if (demo) { demoTimer.restart(); return }
        Greetd.cancelSession()
        Greetd.createSession(user)
    }

    function fail() {
        busy = false
        failed = true
        password = ""
    }

    function launch() {
        const s = session
        const names = (s.desktopNames || s.name).replace(/;$/, "")
        const env = [
            "XDG_SESSION_TYPE=wayland",
            "XDG_CURRENT_DESKTOP=" + names.replace(/;/g, ":"),
            "XDG_SESSION_DESKTOP=" + names.split(";")[0]
        ]
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2"', "sh", s.name, Quickshell.env("GREETER_STATE") || "/dev/null"])
        starting = true
        busy = false
        password = ""
        // Launch cierra el greeter; greetd arranca la sesión al terminar.
        if (demo) Qt.quit()
        else Greetd.launch(s.exec.split(" "), env)
    }

    Timer { id: demoTimer; interval: 600; onTriggered: root.password === "demo" ? root.launch() : root.fail() }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password)
        }
        function onAuthFailure(message) { root.fail() }
        function onReadyToLaunch() { root.launch() }
        function onError(error) { root.fail() }
    }

    FileView {
        path: Quickshell.env("GREETER_CONFIG") || ""
        onLoaded: root.applyConfig(text())
    }
    FileView {
        path: Quickshell.env("GREETER_STATE") || ""
        onLoaded: { root.lastSession = text().trim(); root.pickLast() }
    }

    FloatingWindow {
        id: win
        visible: true
        color: Theme.crust
        implicitWidth: 1280
        implicitHeight: 800

        Item {
            id: scene
            anchors.fill: parent

            // ── Fondo: degradado con manchas de color que derivan despacio ──
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.mantle }
                    GradientStop { position: 1.0; color: Theme.crust }
                }
            }
            Item {
                id: orbs
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }

                Rectangle {
                    id: o1
                    width: scene.height * 0.8; height: width; radius: width / 2
                    color: Theme.mauve; opacity: 0.22
                    x: scene.width * 0.08; y: scene.height * 0.05
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        NumberAnimation { to: scene.width * 0.18; duration: 14000; easing.type: Easing.InOutSine }
                        NumberAnimation { to: scene.width * 0.04; duration: 14000; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle {
                    id: o2
                    width: scene.height * 0.7; height: width; radius: width / 2
                    color: Theme.blue; opacity: 0.20
                    x: scene.width * 0.62; y: scene.height * 0.35
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        NumberAnimation { to: scene.height * 0.5; duration: 17000; easing.type: Easing.InOutSine }
                        NumberAnimation { to: scene.height * 0.2; duration: 17000; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle {
                    width: scene.height * 0.5; height: width; radius: width / 2
                    color: Theme.pink; opacity: 0.14
                    x: scene.width * 0.42; y: scene.height * 0.62
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        NumberAnimation { to: scene.width * 0.30; duration: 19000; easing.type: Easing.InOutSine }
                        NumberAnimation { to: scene.width * 0.52; duration: 19000; easing.type: Easing.InOutSine }
                    }
                }
            }
            Rectangle { anchors.fill: parent; color: Theme.crust; opacity: 0.25 }

            // Clic fuera del select lo cierra.
            MouseArea { anchors.fill: parent; enabled: select.open; onClicked: select.open = false }

            // ── Reloj ──
            Column {
                id: clockCol
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.10 }
                spacing: 6
                opacity: root.starting ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 350 } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 96; weight: Font.Thin }
                    text: Qt.formatTime(tick.now, "HH:mm")
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 17; letterSpacing: 0.5 }
                    text: Qt.locale("es_CO").toString(tick.now, "dddd, d 'de' MMMM")
                }
            }
            QtObject { id: tick; property date now: new Date() }
            Timer { running: true; repeat: true; interval: 1000; onTriggered: tick.now = new Date() }

            // ── Tarjeta de acceso ──
            Rectangle {
                id: card
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 60
                width: 360
                height: cardCol.implicitHeight + 52
                radius: 24
                color: Qt.alpha(Theme.base, 0.62)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.10)
                opacity: root.starting ? 0 : 1
                scale: root.starting ? 0.96 : 1
                Behavior on opacity { NumberAnimation { duration: 350 } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -12; duration: 40 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6; duration: 60 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40 }
                }
                Connections { target: root; function onFailedChanged() { if (root.failed) shake.restart() } }

                ColumnLayout {
                    id: cardCol
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 26 }
                    spacing: 16

                    // Avatar con anillo
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 88; height: 88; radius: 44
                        color: "transparent"
                        border.width: 2
                        border.color: root.failed ? Theme.red : Theme.mauve
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 76; height: 76; radius: 38
                            color: Theme.surface0
                            Text {
                                anchors.centerIn: parent
                                text: root.displayName.charAt(0).toUpperCase()
                                color: Theme.mauvePastel
                                font { family: Theme.font; pixelSize: 34; weight: Font.Medium }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.displayName
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 19; weight: Font.Medium }
                    }

                    // Contraseña
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 14
                        color: Qt.alpha(Theme.crust, 0.6)
                        border.width: 1
                        border.color: root.failed ? Theme.red
                            : pass.activeFocus ? Qt.alpha(Theme.mauve, 0.8) : Theme.surface1
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: pass
                            anchors { fill: parent; leftMargin: 16; rightMargin: 52 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 15 }
                            enabled: !root.busy && !root.starting
                            clip: true
                            focus: true
                            text: root.password
                            onTextChanged: { root.password = text; if (text !== "") root.failed = false }
                            Connections { target: root; function onPasswordChanged() { if (root.password === "") pass.text = "" } }
                            Keys.onReturnPressed: root.submit()
                            Keys.onEnterPressed: root.submit()
                            Keys.onUpPressed: root.cycle(-1)
                            Keys.onDownPressed: root.cycle(1)
                            Keys.onEscapePressed: select.open = false

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pass.text === ""
                                text: root.busy ? "Verificando…" : "Contraseña"
                                color: Theme.overlay0
                                font: pass.font
                            }
                        }

                        Rectangle {
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            width: 36; height: 36; radius: 10
                            color: goArea.containsMouse ? Theme.mauve : Qt.alpha(Theme.mauve, 0.85)
                            opacity: root.password !== "" || root.busy ? 1 : 0.35
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                visible: !root.busy
                                text: "\u{f0054}"   // flecha derecha
                                color: Theme.crust
                                font { family: Theme.font; pixelSize: 18 }
                            }
                            LoadingRing {
                                anchors.centerIn: parent
                                width: 20; height: 20
                                visible: root.busy
                                lineWidth: 2.5
                                color: Theme.crust
                                track: "transparent"
                            }
                            MouseArea {
                                id: goArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submit()
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 14
                        text: root.failed ? "Contraseña incorrecta" : ""
                        color: Theme.red
                        font { family: Theme.font; pixelSize: 12 }
                    }

                    // Selector de sesión (select desplegable)
                    Item {
                        id: select
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        property bool open: false
                        z: 10

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: selArea.containsMouse || select.open ? Theme.surface0 : "transparent"
                            border.width: 1
                            border.color: select.open ? Qt.alpha(Theme.mauve, 0.7) : Theme.surface1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                text: "\u{f0379}"   // monitor
                                color: Theme.mauve
                                font { family: Theme.font; pixelSize: 16 }
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: 42; verticalCenter: parent.verticalCenter }
                                text: root.cleanName(root.session.name)
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 13 }
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                text: "\u{f0140}"   // chevron abajo
                                color: Theme.overlay1
                                rotation: select.open ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 150 } }
                                font { family: Theme.font; pixelSize: 16 }
                            }
                            MouseArea {
                                id: selArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: select.open = !select.open
                            }
                        }

                        // Lista desplegable (flota sobre la tarjeta, no la estira)
                        Rectangle {
                            id: dropdown
                            visible: opacity > 0
                            opacity: select.open ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            anchors { top: parent.bottom; topMargin: 6; left: parent.left; right: parent.right }
                            height: opts.implicitHeight + 8
                            radius: 12
                            color: Qt.alpha(Theme.mantle, 0.96)
                            border.width: 1
                            border.color: Qt.alpha(Theme.text, 0.12)

                            Column {
                                id: opts
                                anchors { fill: parent; margins: 4 }
                                Repeater {
                                    model: root.sessions
                                    Rectangle {
                                        id: opt
                                        required property var modelData
                                        required property int index
                                        readonly property bool sel: index === root.sessionIdx
                                        width: opts.width; height: 36; radius: 8
                                        color: optArea.containsMouse ? Theme.surface0 : "transparent"
                                        Text {
                                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                            text: root.cleanName(opt.modelData.name)
                                            color: opt.sel ? Theme.mauvePastel : Theme.subtext1
                                            font { family: Theme.font; pixelSize: 13 }
                                        }
                                        Text {
                                            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                            visible: opt.sel
                                            text: "\u{f012c}"   // check
                                            color: Theme.mauve
                                            font { family: Theme.font; pixelSize: 15 }
                                        }
                                        MouseArea {
                                            id: optArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.sessionIdx = opt.index; select.open = false; pass.forceActiveFocus() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Botones de energía ──
            Row {
                anchors { right: parent.right; bottom: parent.bottom; margins: 32 }
                spacing: 10
                opacity: root.starting ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 250 } }
                Repeater {
                    model: [
                        { icon: "\u{f04b2}", color: Theme.blue,  cmd: ["systemctl", "suspend"] },
                        { icon: "\u{f0709}", color: Theme.peach, cmd: ["systemctl", "reboot"] },
                        { icon: "\u{f0425}", color: Theme.red,   cmd: ["systemctl", "poweroff"] }
                    ]
                    Rectangle {
                        id: pb
                        required property var modelData
                        width: 44; height: 44; radius: 14
                        color: pbArea.containsMouse ? Qt.alpha(modelData.color, 0.18) : Qt.alpha(Theme.base, 0.55)
                        border.width: 1
                        border.color: pbArea.containsMouse ? Qt.alpha(modelData.color, 0.6) : Qt.alpha(Theme.text, 0.08)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: pb.modelData.icon
                            color: pb.modelData.color
                            font { family: Theme.font; pixelSize: 19 }
                        }
                        MouseArea {
                            id: pbArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (!root.demo) Quickshell.execDetached(pb.modelData.cmd)
                        }
                    }
                }
            }

            // Marca de modo demo
            Text {
                visible: root.demo
                anchors { left: parent.left; bottom: parent.bottom; margins: 24 }
                text: "modo demo · contraseña: demo"
                color: Theme.overlay0
                font { family: Theme.font; pixelSize: 11 }
            }
        }

        // Cierra el foco en el campo de contraseña al arrancar.
        Component.onCompleted: pass.forceActiveFocus()
    }
}
