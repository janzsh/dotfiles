// Temporizador de cuenta regresiva (vista: CountdownView.qml). Vive en
// shell.qml, fuera del popup, para seguir corriendo con el panel cerrado.
// Al llegar a 0 avisa con Ringer. Guarda duración y tono en
// ~/.local/state/quickshell-countdown.json.

import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    required property var ringer

    property int presetSec: 300       // duración configurada
    property int remaining: 300
    property bool running: false
    property real endAt: 0
    property string sound: "/run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

    // Hay algo en curso (corriendo o pausado a medias): se muestra en la barra.
    readonly property bool active: running || remaining < presetSec

    function fmt(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60
        const p = n => (n < 10 ? "0" : "") + n
        return (h > 0 ? h + ":" : "") + p(m) + ":" + p(s)
    }

    function setPreset(sec) {
        presetSec = Math.max(1, Math.min(sec, 99 * 3600 + 59 * 60 + 59))
        if (!running) remaining = presetSec
        save()
    }
    function adjust(delta) { setPreset(presetSec + delta) }

    function tick() {
        remaining = Math.max(0, Math.ceil((endAt - Date.now()) / 1000))
        if (remaining <= 0) finish()
    }
    function start() { if (remaining > 0) { endAt = Date.now() + remaining * 1000; running = true } }
    function pause() { tick(); running = false }
    function toggle() { running ? pause() : start() }
    function reset() { running = false; remaining = presetSec }
    function finish() {
        running = false
        remaining = presetSec
        ringer.ring("Temporizador", "Se acabó el tiempo (" + fmt(presetSec) + ")", sound, false, null)
    }

    function save() {
        store.setText(JSON.stringify({ presetSec, sound }))
    }

    Timer {
        interval: 250
        repeat: true
        running: root.running
        onTriggered: root.tick()
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/quickshell-countdown.json"
        printErrors: false
        onLoaded: {
            try {
                const c = JSON.parse(text())
                if (typeof c.sound === "string") root.sound = c.sound
                if (c.presetSec > 0) { root.presetSec = c.presetSec; if (!root.running) root.remaining = c.presetSec }
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "countdown"
        function toggle(): void { root.toggle() }
        function reset(): void { root.reset() }
    }
}
