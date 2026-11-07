// Alarmas: lista guardada en ~/.local/state/quickshell-alarms.json, revisada
// cada segundo (suena aunque el panel esté cerrado). Sin días marcados = una
// sola vez (se desactiva al sonar); con días = se repite esos días.
// Al sonar avisa con Ringer (con "Posponer 5 min"). Vista: AlarmsView.qml.
// Editor: ventana flotante a pantalla completa (como el ajuste del pomodoro).

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    required property var ringer

    // [{ h, m, days: [7 bool, lunes primero], on }]
    property var list: []
    property string sound: "/run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

    // Editor
    property bool editing: false
    property int editIdx: -1       // -1 = alarma nueva
    property int eh: 7
    property int em: 0
    property var edays: [false, false, false, false, false, false, false]

    property string lastKey: ""
    property real snoozeAt: 0

    readonly property var dayNames: ["L", "M", "X", "J", "V", "S", "D"]

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function timeText(a) { return pad(a.h) + ":" + pad(a.m) }
    function daysText(a) {
        const n = a.days.filter(d => d).length
        if (n === 0) return "Una vez"
        if (n === 7) return "Todos los días"
        if (n === 5 && !a.days[5] && !a.days[6]) return "Lun – Vie"
        if (n === 2 && a.days[5] && a.days[6]) return "Fin de semana"
        return dayNames.filter((_, i) => a.days[i]).join(" ")
    }
    // Próxima alarma activa, para mostrarla en la vista: "07:30" o "".
    function nextText() {
        const now = new Date()
        let best = null, bestMs = Infinity
        for (const a of list) {
            if (!a.on) continue
            for (let add = 0; add < 8; add++) {
                const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + add, a.h, a.m)
                const dow = (d.getDay() + 6) % 7
                const okDay = a.days.every(x => !x) || a.days[dow]
                if (okDay && d > now) { if (d - now < bestMs) { bestMs = d - now; best = d } break }
            }
        }
        if (!best) return ""
        const mins = Math.round(bestMs / 60000)
        const h = Math.floor(mins / 60), m = mins % 60
        return "Suena en " + (h > 0 ? h + " h " : "") + m + " min"
    }

    function save() { store.setText(JSON.stringify({ sound, list })) }

    function openEditor(idx) {
        editIdx = idx
        if (idx >= 0) {
            eh = list[idx].h; em = list[idx].m; edays = list[idx].days.slice()
        } else {
            const d = new Date()
            eh = (d.getHours() + 1) % 24; em = 0
            edays = [false, false, false, false, false, false, false]
        }
        editing = true
    }
    function commit() {
        const a = { h: eh, m: em, days: edays.slice(), on: true }
        const l = list.slice()
        if (editIdx >= 0) l[editIdx] = a; else l.push(a)
        list = l
        editing = false
        save()
    }
    function remove() {
        if (editIdx >= 0) { const l = list.slice(); l.splice(editIdx, 1); list = l; save() }
        editing = false
    }
    function toggle(i) {
        const l = list.slice()
        l[i] = Object.assign({}, l[i], { on: !l[i].on })
        list = l
        save()
    }
    function toggleDay(i) {
        const d = edays.slice(); d[i] = !d[i]; edays = d
    }

    function fire(a) {
        ringer.ring("Alarma", timeText(a), sound, true, () => { snoozeAt = Date.now() + 5 * 60000 })
    }
    function check() {
        const d = clock.date
        if (snoozeAt > 0 && Date.now() >= snoozeAt) {
            snoozeAt = 0
            ringer.ring("Alarma", "Pospuesta", sound, true, () => { snoozeAt = Date.now() + 5 * 60000 })
        }
        const key = d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate() + " " + d.getHours() + ":" + d.getMinutes()
        if (key === lastKey) return
        lastKey = key
        const dow = (d.getDay() + 6) % 7
        let changed = false
        const l = list.slice()
        for (let i = 0; i < l.length; i++) {
            const a = l[i]
            if (!a.on || a.h !== d.getHours() || a.m !== d.getMinutes()) continue
            const once = a.days.every(x => !x)
            if (!once && !a.days[dow]) continue
            fire(a)
            if (once) { l[i] = Object.assign({}, a, { on: false }); changed = true }
        }
        if (changed) { list = l; save() }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        onDateChanged: root.check()
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/quickshell-alarms.json"
        printErrors: false
        onLoaded: {
            try {
                const c = JSON.parse(text())
                if (typeof c.sound === "string") root.sound = c.sound
                if (Array.isArray(c.list)) root.list = c.list
            } catch (e) {}
        }
    }

    PanelWindow {
        visible: root.editing
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-alarm-editor"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) keys.forceActiveFocus()

        Rectangle {
            anchors.fill: parent
            color: Theme.crust
            opacity: 0.45
            MouseArea { anchors.fill: parent; onClicked: root.editing = false }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { root.editing = false; event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.commit(); event.accepted = true }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 420
            height: form.implicitHeight + 48
            radius: 16
            color: Theme.base
            border.width: 1
            border.color: Theme.surface0

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: form
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                spacing: 16

                Text {
                    text: root.editIdx >= 0 ? "Editar alarma" : "Nueva alarma"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 18; weight: Font.Bold }
                }

                // Hora : minutos
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    Repeater {
                        model: [
                            { isHour: true,  step: 1 },
                            { isHour: false, step: 1 }
                        ]
                        Column {
                            id: fld
                            required property var modelData
                            spacing: 4
                            readonly property int val: modelData.isHour ? root.eh : root.em
                            function bump(d) {
                                if (modelData.isHour) root.eh = (root.eh + d + 24) % 24
                                else root.em = (root.em + d + 60) % 60
                            }
                            IconButton { anchors.horizontalCenter: parent.horizontalCenter; size: 30; iconSize: 14
                                         icon: "\u{f0143}"; onClicked: fld.bump(1) }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.pad(fld.val)
                                color: Theme.yellow
                                font { family: Theme.font; pixelSize: 52; weight: Font.Bold }
                            }
                            IconButton { anchors.horizontalCenter: parent.horizontalCenter; size: 30; iconSize: 14
                                         icon: "\u{f0140}"; onClicked: fld.bump(-1) }
                        }
                    }
                }

                // Días de repetición
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Repeater {
                        model: root.dayNames
                        Rectangle {
                            id: dchip
                            required property string modelData
                            required property int index
                            readonly property bool sel: root.edays[index]
                            width: 40; height: 36; radius: 10
                            color: sel ? Theme.yellow : dma.containsMouse ? Theme.surface1 : Theme.surface0
                            Text {
                                anchors.centerIn: parent
                                text: dchip.modelData
                                color: dchip.sel ? Theme.crust : index >= 5 ? Theme.peach : Theme.text
                                font { family: Theme.font; pixelSize: 13; weight: Font.Bold }
                            }
                            MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleDay(dchip.index) }
                        }
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.edays.some(d => d) ? "Se repite los días marcados" : "Sin días marcados: suena una sola vez"
                    color: Theme.overlay1
                    font { family: Theme.font; pixelSize: 11 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        visible: root.editIdx >= 0
                        Layout.preferredWidth: 40; height: 36; radius: 10
                        color: delMa.containsMouse ? Qt.lighter(Theme.red, 1.1) : Qt.alpha(Theme.red, 0.8)
                        Text { anchors.centerIn: parent; text: "\u{f01b4}"; color: Theme.crust
                               font { family: Theme.font; pixelSize: 16 } }
                        MouseArea { id: delMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: root.remove() }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36; radius: 10
                        color: canMa.containsMouse ? Theme.surface1 : Theme.surface0
                        Text { anchors.centerIn: parent; text: "Cancelar"; color: Theme.text
                               font { family: Theme.font; pixelSize: 12 } }
                        MouseArea { id: canMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: root.editing = false }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36; radius: 10
                        color: okMa.containsMouse ? Qt.lighter(Theme.yellow, 1.1) : Theme.yellow
                        Text { anchors.centerIn: parent; text: "Guardar"; color: Theme.crust
                               font { family: Theme.font; pixelSize: 12; weight: Font.Bold } }
                        MouseArea { id: okMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor; onClicked: root.commit() }
                    }
                }
            }
        }
    }
}
