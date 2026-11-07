// Reloj + fecha en la barra. Con hover de 2 s abre un panel tipo carrusel
// (flechas/puntos abajo para cambiar de vista): calendario mensual (semana
// desde lunes; flechas cambian de mes, clic en el título vuelve a hoy) y
// pomodoro, alarmas, temporizador y cronómetro (*View.qml). Para añadir una vista: sube `pages`, añade su item
// con `visible: root.page === N`.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    readonly property var loc: Qt.locale("es_CO")
    property date viewDate: new Date()
    required property var pomo        // Pomodoro, Alarms y Countdown: el estado
    required property var alarms      // vive en shell.qml (siguen con el panel cerrado)
    required property var countdown
    required property var stopwatch
    readonly property int pages: 5
    property int page: 0
    function go(n) { page = (page + n + pages) % pages }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 36
    popupWidth: 360

    // Un popup de Wayland no recibe teclado sin agarrarlo (y eso rompe el clic
    // que lo abre), así que las vistas también cambian con la rueda del mouse
    // sobre el panel y por IPC:  qs ipc call calendar next | prev
    IpcHandler {
        target: "calendar"
        function next(): void { root.go(1) }
        function prev(): void { root.go(-1) }
    }

    onOpenChanged: if (!open) viewDate = new Date()

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.hovered ? Theme.surface0 : "transparent"
    }

    Row {
        id: label
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF00ED)
            color: Theme.mauve
            font { family: Theme.font; pixelSize: Theme.iconSize }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
            text: root.loc.toString(clock.date, "ddd d MMM") + "   "
                + root.loc.toString(clock.date, "HH:mm")
        }
        // Temporizador en curso (o pausado a medias): tiempo restante en la barra.
        Text {
            visible: root.countdown.active
            anchors.verticalCenter: parent.verticalCenter
            color: root.countdown.running ? Theme.ok : Theme.overlay1
            font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
            text: String.fromCodePoint(0xF051B) + " " + root.countdown.fmt(root.countdown.remaining)
        }
        // Cronómetro en curso (o pausado con tiempo): tiempo transcurrido en la barra.
        Text {
            visible: root.stopwatch.active
            anchors.verticalCenter: parent.verticalCenter
            color: root.stopwatch.running ? Theme.yellow : Theme.overlay1
            font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
            text: String.fromCodePoint(0xF04C5) + " " + root.stopwatch.fmt(root.stopwatch.elapsed, false)
        }
        // Pomodoro en curso (o pausado a medias): tiempo restante en la barra.
        Text {
            visible: root.pomo.active
            anchors.verticalCenter: parent.verticalCenter
            color: root.pomo.running ? root.pomo.phaseColor : Theme.overlay1
            font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
            text: String.fromCodePoint(0xF13AB) + " " + root.pomo.fmt(root.pomo.remaining)
        }
    }

    popup: Component {
        ColumnLayout {
            spacing: 14

            WheelHandler {
                onWheel: event => root.go(event.angleDelta.y < 0 ? 1 : -1)
            }

            // Todas las vistas ocupan el alto de la más alta: si el panel se
            // encogiera al cambiar de vista, el cursor quedaría fuera de él y
            // el popup se cerraría solo.
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(cal.implicitHeight, pv.implicitHeight,
                                         av.implicitHeight, cv.implicitHeight,
                                         sv.implicitHeight)


                ColumnLayout {
                    id: cal
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    visible: root.page === 0
                    spacing: 14
                    implicitHeight: childrenRect.height

                    readonly property int year: root.viewDate.getFullYear()
                    readonly property int month: root.viewDate.getMonth()
                    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7

                    function shift(n) { root.viewDate = new Date(year, month + n, 1) }

                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: prevMa.containsMouse ? Theme.surface1 : Theme.surface0
                            Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.text
                                   font { family: Theme.font; pixelSize: Theme.iconSize } }
                            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: cal.shift(-1) }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: {
                                const m = root.loc.monthName(cal.month, Locale.LongFormat)
                                return m.charAt(0).toUpperCase() + m.slice(1) + " " + cal.year
                            }
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 16; weight: Font.Bold }
                            MouseArea { anchors.fill: parent; onClicked: root.viewDate = new Date() }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 32; height: 32; radius: 10
                            color: nextMa.containsMouse ? Theme.surface1 : Theme.surface0
                            Text { anchors.centerIn: parent; text: "󰅂"; color: Theme.text
                                   font { family: Theme.font; pixelSize: Theme.iconSize } }
                            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: cal.shift(1) }
                        }
                    }

                    Grid {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 7
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: ["L", "M", "X", "J", "V", "S", "D"]
                            Text {
                                width: 38; height: 22
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: index >= 5 ? Theme.peach : Theme.overlay1
                                font { family: Theme.font; pixelSize: 11; weight: Font.Bold }
                            }
                        }

                        Repeater {
                            model: 42
                            Rectangle {
                                readonly property date d: new Date(cal.year, cal.month, 1 - cal.offset + index)
                                readonly property bool inMonth: d.getMonth() === cal.month
                                readonly property bool today: d.toDateString() === clock.date.toDateString()
                                width: 38; height: 34; radius: 10
                                color: today ? Theme.mauve : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.d.getDate()
                                    color: parent.today ? Theme.crust
                                         : !parent.inMonth ? Theme.surface2
                                         : index % 7 >= 5 ? Theme.peach : Theme.text
                                    font { family: Theme.font; pixelSize: 13
                                           weight: parent.today ? Font.Bold : Font.Normal }
                                }
                            }
                        }
                    }
                }

                PomodoroView {
                    id: pv
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    visible: root.page === 1
                    pomo: root.pomo
                    onOpenSettings: { root.close(); root.pomo.settingsShown = true }
                }

                AlarmsView {
                    id: av
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    visible: root.page === 2
                    al: root.alarms
                    pomo: root.pomo
                    onEditRequested: idx => { root.close(); root.alarms.openEditor(idx) }
                }

                CountdownView {
                    id: cv
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    visible: root.page === 3
                    cd: root.countdown
                    pomo: root.pomo
                }

                StopwatchView {
                    id: sv
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    visible: root.page === 4
                    sw: root.stopwatch
                }
            }

            // Carrusel: flechas + puntos para cambiar de vista.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Text {
                    text: "󰅁"; color: prevPage.containsMouse ? Theme.text : Theme.overlay1
                    font { family: Theme.font; pixelSize: Theme.iconSize }
                    MouseArea { id: prevPage; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: root.go(-1) }
                }
                Repeater {
                    model: root.pages
                    Rectangle {
                        // Layout.preferredWidth (no width): un RowLayout solo se
                        // redistribuye si cambia el tamaño que el hijo le declara.
                        Layout.preferredWidth: index === root.page ? 16 : 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: index === root.page ? Theme.mauve : Theme.surface2
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150 } }
                    }
                }
                Text {
                    text: "󰅂"; color: nextPage.containsMouse ? Theme.text : Theme.overlay1
                    font { family: Theme.font; pixelSize: Theme.iconSize }
                    MouseArea { id: nextPage; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: root.go(1) }
                }
            }
        }
    }
}
