// Página "Pomodoro" del carrusel del calendario. Solo dibuja: el estado y el
// temporizador viven en Pomodoro.qml (`pomo`).

import QtQuick
import QtQuick.Layouts

Item {
    id: view

    required property var pomo
    signal openSettings()

    // Item + anclas (no ColumnLayout directo): así ocupa todo el ancho del
    // panel y el contenido queda centrado.
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 14

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: view.pomo.phaseLabel
            color: view.pomo.phaseColor
            font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 180; height: 180

            Canvas {
                id: ring
                anchors.fill: parent
                readonly property real frac: view.pomo.total > 0 ? view.pomo.remaining / view.pomo.total : 0
                readonly property color fg: view.pomo.phaseColor
                readonly property color bg: Theme.surface0
                onFracChanged: requestPaint()
                onFgChanged: requestPaint()
                onBgChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const c = width / 2, r = c - 8
                    ctx.lineWidth = 8
                    ctx.lineCap = "round"
                    ctx.strokeStyle = bg
                    ctx.beginPath(); ctx.arc(c, c, r, 0, 2 * Math.PI); ctx.stroke()
                    if (frac > 0) {
                        ctx.strokeStyle = fg
                        ctx.beginPath()
                        ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * frac)
                        ctx.stroke()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: view.pomo.fmt(view.pomo.remaining)
                color: Theme.text
                font { family: Theme.font; pixelSize: 38; weight: Font.Bold }
            }
        }

        // Pomodoros del ciclo actual (se llenan hasta el descanso largo).
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: view.pomo.longEvery
                Rectangle {
                    width: 10; height: 10; radius: 5
                    readonly property int filled: view.pomo.phase === "long"
                        ? view.pomo.longEvery : view.pomo.done % view.pomo.longEvery
                    color: index < filled ? view.pomo.phaseColor : Theme.surface1
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Repeater {
                model: [
                    { icon: "\u{f0450}", act: "reset" },     // reiniciar
                    { icon: "", act: "toggle" },               // play / pausa
                    { icon: "\u{f04ad}", act: "skip" },       // saltar fase
                    { icon: "\u{f0493}", act: "settings" }    // ajustes
                ]
                Rectangle {
                    id: btn
                    required property var modelData
                    readonly property bool main: modelData.act === "toggle"
                    width: main ? 56 : 40; height: main ? 56 : 40
                    radius: main ? 18 : 12
                    color: main ? (ma.containsMouse ? Qt.lighter(view.pomo.phaseColor, 1.1) : view.pomo.phaseColor)
                                : (ma.containsMouse ? Theme.surface1 : Theme.surface0)
                    Text {
                        anchors.centerIn: parent
                        text: btn.main ? (view.pomo.running ? "\u{f03e4}" : "\u{f040a}") : btn.modelData.icon
                        color: btn.main ? Theme.crust : Theme.text
                        font { family: Theme.font; pixelSize: btn.main ? 26 : 18 }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            switch (btn.modelData.act) {
                            case "reset": view.pomo.reset(); break
                            case "toggle": view.pomo.toggle(); break
                            case "skip": view.pomo.skip(); break
                            case "settings": view.openSettings(); break
                            }
                        }
                    }
                }
            }
        }
    }
}
