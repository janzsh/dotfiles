// Cronómetro (vista: StopwatchView.qml). Vive en shell.qml, fuera del popup,
// para seguir corriendo con el panel cerrado. Mide con Date.now(), así que no
// deriva aunque el timer de refresco se retrase.

import Quickshell
import QtQuick
import Quickshell.Io

Scope {
    id: root

    property bool running: false
    property real startedAt: 0      // Date.now() del último arranque
    property real accumulated: 0    // ms acumulados antes del último arranque
    property real elapsed: 0        // ms totales, refrescado por el timer
    property var laps: []           // [{ lap: ms de la vuelta, total: ms }], la más reciente primero

    // Hay algo que mostrar (corriendo o pausado con tiempo): va en la barra.
    readonly property bool active: running || elapsed > 0

    // h:mm:ss o mm:ss; con `cents` añade centésimas.
    function fmt(ms, cents) {
        const t = Math.floor(ms / 10)
        const c = t % 100, s = Math.floor(t / 100) % 60
        const m = Math.floor(t / 6000) % 60, h = Math.floor(t / 360000)
        const p = n => (n < 10 ? "0" : "") + n
        return (h > 0 ? h + ":" : "") + p(m) + ":" + p(s) + (cents === false ? "" : "." + p(c))
    }

    function tick() { elapsed = accumulated + (running ? Date.now() - startedAt : 0) }
    function start() { startedAt = Date.now(); running = true; tick() }
    function pause() { tick(); accumulated = elapsed; running = false }
    function toggle() { running ? pause() : start() }
    function lap() {
        if (!running) return
        tick()
        const prev = laps.length > 0 ? laps[0].total : 0
        laps = [{ lap: elapsed - prev, total: elapsed }].concat(laps)
    }
    function reset() { running = false; accumulated = 0; elapsed = 0; laps = [] }

    Timer {
        interval: 33
        repeat: true
        running: root.running
        onTriggered: root.tick()
    }

    IpcHandler {
        target: "stopwatch"
        function toggle(): void { root.toggle() }
        function lap(): void { root.lap() }
        function reset(): void { root.reset() }
    }
}
