// Estado y lógica del pomodoro + ventana flotante de ajustes (a pantalla
// completa, como PowerMenu). Vive en shell.qml, fuera de cualquier popup, para
// que el temporizador siga corriendo con el panel cerrado.
// La vista está en PomodoroView.qml (carrusel del calendario).
// IPC:  qs ipc call pomodoro toggle | reset | skip | settings
// Ajustes guardados en ~/.cache/pomodoro.json. Por defecto 25 / 5 / 15, cada 4.
// Sonidos (vía pw-play): tono al terminar cada fase y sonido de fondo mientras
// corre el enfoque (tic-tac o cualquier archivo). Además de los del sistema
// salen los archivos que pongas en sounds/ (junto a este archivo, ignorado por git).

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    required property var ringer

    // Ajustes (minutos)
    property int workMin: 25
    property int shortMin: 5
    property int longMin: 15
    property int longEvery: 4      // pomodoros hasta el descanso largo
    // Sonidos: ruta de archivo; "" = ninguno; ambient también admite "tick".
    property string finishSound: "/run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
    property string ambient: ""
    property int ambientVol: 40    // %

    // Estado
    property string phase: "work"  // "work" | "short" | "long"
    property bool running: false
    property int remaining: workMin * 60   // segundos
    property int done: 0           // pomodoros completados
    property real endAt: 0
    property bool settingsShown: false
    property var sounds: []        // [{name, path}] descubiertos al arrancar

    readonly property string home: Quickshell.env("HOME")
    readonly property string soundsDir: Qt.resolvedUrl("sounds").toString().replace("file://", "")
    readonly property string tickPath: home + "/.cache/pomodoro/tick.wav"

    readonly property int total: durationOf(phase) * 60
    // Hay algo en curso (corriendo o pausado a medias): se muestra en la barra.
    readonly property bool active: running || remaining < total
    readonly property color phaseColor: phase === "work" ? Theme.mauve
                                      : phase === "short" ? Theme.green : Theme.sky
    readonly property string phaseLabel: phase === "work" ? "Enfoque"
                                       : phase === "short" ? "Descanso corto" : "Descanso largo"

    function durationOf(p) { return p === "work" ? workMin : p === "short" ? shortMin : longMin }
    function fmt(sec) {
        const m = Math.floor(sec / 60), s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function tick() {
        remaining = Math.max(0, Math.ceil((endAt - Date.now()) / 1000))
        if (remaining <= 0) finish()
    }
    function start() { endAt = Date.now() + remaining * 1000; running = true }
    function pause() { tick(); running = false }
    function toggle() { running ? pause() : start() }
    function reset() { running = false; remaining = total }

    // Pasa a la siguiente fase y se queda en pausa esperando al usuario.
    function advance() {
        if (phase === "work") {
            done++
            phase = done % longEvery === 0 ? "long" : "short"
        } else {
            phase = "work"
        }
        running = false
        remaining = durationOf(phase) * 60
    }
    function skip() { advance() }
    // Al terminar una fase: avisa con Ringer (pantalla completa + sonido en
    // bucle hasta Detener) y la siguiente fase queda lista, en pausa.
    function finish() {
        const was = phase
        advance()
        ringer.ring(was === "work" ? "Pomodoro completado" : "Descanso terminado",
                    "Siguiente: " + phaseLabel.toLowerCase() + " · " + durationOf(phase) + " min",
                    finishSound, false, null, phaseColor)
    }

    // --- sonidos ---
    function choices(withTick) {
        const base = [{ name: "Ninguno", path: "" }]
        if (withTick) base.push({ name: "Tic-tac", path: "tick" })
        return base.concat(sounds)
    }
    // Prueba corta (máx. 6 s) de un sonido.
    function preview(path, vol) {
        const p = path === "tick" ? tickPath : path
        if (p !== "") Quickshell.execDetached(["timeout", "6", "pw-play", "--volume=" + vol, p])
    }
    function syncAmbient() {
        const p = ambient === "tick" ? tickPath : ambient
        if (running && phase === "work" && p !== "") {
            amb.command = ["pw-play", "--volume=" + (ambientVol / 100).toFixed(2), p]
            amb.running = true
        } else {
            amb.running = false
        }
    }
    // Cambio de sonido/volumen en caliente: se corta y onExited lo relanza.
    function restartAmbient() { amb.running ? amb.running = false : syncAmbient() }
    onRunningChanged: syncAmbient()
    onPhaseChanged: syncAmbient()
    onAmbientChanged: restartAmbient()
    onAmbientVolChanged: restartAmbient()

    // Ajustes: al cambiar, si no hay nada en curso se refresca el tiempo.
    function applySettings() {
        if (!active || remaining > total) remaining = total
        save()
    }
    function restoreDefaults() {
        workMin = 25; shortMin = 5; longMin = 15; longEvery = 4
        applySettings()
    }

    function save() {
        store.setText(JSON.stringify({ workMin, shortMin, longMin, longEvery,
                                       finishSound, ambient, ambientVol }))
    }

    Timer {
        interval: 250
        repeat: true
        running: root.running
        onTriggered: root.tick()
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.cache/pomodoro.json"
        printErrors: false   // la primera vez el archivo no existe
        onLoaded: {
            try {
                const c = JSON.parse(text())
                if (c.workMin > 0) root.workMin = c.workMin
                if (c.shortMin > 0) root.shortMin = c.shortMin
                if (c.longMin > 0) root.longMin = c.longMin
                if (c.longEvery > 0) root.longEvery = c.longEvery
                if (typeof c.finishSound === "string") root.finishSound = c.finishSound
                if (typeof c.ambient === "string") root.ambient = c.ambient
                if (c.ambientVol >= 5) root.ambientVol = c.ambientVol
                if (!root.running) root.remaining = root.total
            } catch (e) {}
        }
    }

    // Sonido de fondo en bucle: al terminar el archivo se relanza si sigue activo.
    Process { id: amb; onExited: root.syncAmbient() }

    // Genera el tic-tac la primera vez.
    Process {
        running: true
        command: ["sh", "-c", '[ -f "$2" ] || python3 "$1" "$2"', "sh",
                  Qt.resolvedUrl("pomodoro-tick.py").toString().replace("file://", ""),
                  root.tickPath]
    }

    // Descubre sonidos: primero los tuyos, luego alarmas del sistema.
    Process {
        running: true
        command: ["sh", "-c",
            'find -L "$1" /run/current-system/sw/share/sounds/gnome/default/alarms ' +
            '/run/current-system/sw/share/sounds/freedesktop/stereo -maxdepth 1 -type f ' +
            '\\( -name "*.oga" -o -name "*.ogg" -o -name "*.wav" -o -name "*.mp3" -o -name "*.flac" \\) ' +
            '2>/dev/null | grep -v -e audio-channel -e audio-test -e suspend-error',
            "sh", root.soundsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.sounds = text.split("\n").filter(l => l !== "").map(p => ({
                    name: p.split("/").pop().replace(/\.[^.]+$/, ""), path: p }))
            }
        }
    }

    IpcHandler {
        target: "pomodoro"
        function toggle(): void { root.toggle() }
        function reset(): void { root.reset() }
        function skip(): void { root.skip() }
        function settings(): void { root.settingsShown = !root.settingsShown }
    }

    PanelWindow {
        visible: root.settingsShown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-pomodoro"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
            opacity: 0.45
            MouseArea { anchors.fill: parent; onClicked: root.settingsShown = false }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.settingsShown = false
                    event.accepted = true
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 480
            height: form.implicitHeight + 48
            radius: 16
            color: Theme.base
            border.width: 1
            border.color: Theme.surface0

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: form
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                spacing: 14

                Text {
                    text: "Pomodoro"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 18; weight: Font.Bold }
                }

                Repeater {
                    model: [
                        { label: "Enfoque",          unit: "min",  prop: "workMin",   min: 1, max: 120, color: Theme.mauve },
                        { label: "Descanso corto",   unit: "min",  prop: "shortMin",  min: 1, max: 60,  color: Theme.green },
                        { label: "Descanso largo",   unit: "min",  prop: "longMin",   min: 1, max: 90,  color: Theme.sky },
                        { label: "Largo cada",       unit: "pomodoros", prop: "longEvery", min: 2, max: 10, color: Theme.peach },
                        { label: "Volumen de fondo", unit: "%",    prop: "ambientVol", min: 5, max: 100, step: 5, color: Theme.ok }
                    ]
                    RowLayout {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle { width: 4; height: 22; radius: 2; color: row.modelData.color }
                        Text {
                            text: row.modelData.label
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13 }
                        }
                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: [-1, 0, 1]
                            Item {
                                id: cell
                                required property int modelData
                                width: modelData === 0 ? 86 : 32
                                height: 32
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    visible: cell.modelData !== 0
                                    color: ma.containsMouse ? Theme.surface1 : Theme.surface0
                                    Text {
                                        anchors.centerIn: parent
                                        text: cell.modelData < 0 ? "−" : "+"
                                        color: Theme.text
                                        font { family: Theme.font; pixelSize: 16 }
                                    }
                                }
                                Text {
                                    visible: cell.modelData === 0
                                    anchors.centerIn: parent
                                    text: root[row.modelData.prop] + " " + row.modelData.unit
                                    color: row.modelData.color
                                    font { family: Theme.font; pixelSize: 13; weight: Font.Bold }
                                }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: cell.modelData !== 0
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const v = root[row.modelData.prop] + cell.modelData * (row.modelData.step || 1)
                                        root[row.modelData.prop] = Math.max(row.modelData.min, Math.min(row.modelData.max, v))
                                        root.applySettings()
                                    }
                                }
                            }
                        }
                    }
                }

                // Selectores de sonido: ‹ nombre › y ▶ para probar.
                Repeater {
                    model: [
                        { label: "Tono al terminar",  prop: "finishSound", tick: false, color: Theme.yellow },
                        { label: "Sonido al avanzar", prop: "ambient",     tick: true,  color: Theme.ok }
                    ]
                    RowLayout {
                        id: prow
                        required property var modelData
                        readonly property var list: root.choices(modelData.tick)
                        readonly property int idx: {
                            const i = list.findIndex(c => c.path === root[modelData.prop])
                            return i < 0 ? 0 : i
                        }
                        function step(d) {
                            const c = list[(idx + d + list.length) % list.length]
                            root[modelData.prop] = c.path
                            root.save()
                            if (!modelData.tick) root.preview(c.path, 1.0)
                        }
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle { width: 4; height: 22; radius: 2; color: prow.modelData.color }
                        Text {
                            text: prow.modelData.label
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13 }
                        }
                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: ["\u{f0141}", "", "\u{f0142}", "\u{f040a}"]
                            Item {
                                id: pc
                                required property int index
                                required property string modelData
                                width: index === 1 ? 130 : 32
                                height: 32
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    visible: pc.index !== 1
                                    color: pma.containsMouse ? Theme.surface1 : Theme.surface0
                                    Text {
                                        anchors.centerIn: parent
                                        text: pc.modelData
                                        color: Theme.text
                                        font { family: Theme.font; pixelSize: 16 }
                                    }
                                }
                                Text {
                                    visible: pc.index === 1
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    text: prow.list[prow.idx].name
                                    color: prow.modelData.color
                                    font { family: Theme.font; pixelSize: 12; weight: Font.Bold }
                                }
                                MouseArea {
                                    id: pma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: pc.index !== 1
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (pc.index === 0) prow.step(-1)
                                        else if (pc.index === 2) prow.step(1)
                                        else root.preview(root[prow.modelData.prop],
                                                          prow.modelData.tick ? root.ambientVol / 100 : 1.0)
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 10
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36; radius: 10
                        color: resetMa.containsMouse ? Theme.surface1 : Theme.surface0
                        Text {
                            anchors.centerIn: parent
                            text: "Restablecer 25 / 5 / 15"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 12 }
                        }
                        MouseArea { id: resetMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.restoreDefaults() }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36; radius: 10
                        color: closeMa.containsMouse ? Qt.lighter(Theme.mauve, 1.1) : Theme.mauve
                        Text {
                            anchors.centerIn: parent
                            text: "Listo"
                            color: Theme.crust
                            font { family: Theme.font; pixelSize: 12; weight: Font.Bold }
                        }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.settingsShown = false }
                    }
                }

                Text {
                    text: "Esc para cerrar"
                    color: Theme.overlay0
                    font { family: Theme.font; pixelSize: 10 }
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
