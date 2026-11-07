// Página "Cronómetro" del carrusel. Solo dibuja; el estado vive en
// Stopwatch.qml (`sw`). Botones: reiniciar, iniciar/pausar, vuelta. La lista de
// vueltas marca la más rápida (verde) y la más lenta (roja).

import QtQuick
import QtQuick.Layouts

Item {
    id: view

    required property var sw

    implicitHeight: col.implicitHeight

    readonly property var lapTimes: view.sw.laps.map(l => l.lap)
    readonly property real best: lapTimes.length > 1 ? Math.min.apply(null, lapTimes) : -1
    readonly property real worst: lapTimes.length > 1 ? Math.max.apply(null, lapTimes) : -1

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 14

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Cronómetro"
            color: Theme.yellow
            font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: view.sw.fmt(view.sw.elapsed)
            color: view.sw.running ? Theme.text : Theme.overlay1
            font { family: Theme.font; pixelSize: 48; weight: Font.Bold }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            IconButton { size: 40; iconSize: 18; icon: "\u{f0450}"; onClicked: view.sw.reset() }
            IconButton {
                size: 56; iconSize: 26; filled: true; accent: Theme.yellow
                icon: view.sw.running ? "\u{f03e4}" : "\u{f040a}"
                onClicked: view.sw.toggle()
            }
            IconButton {
                size: 40; iconSize: 18; icon: "\u{f023b}"   // bandera: marcar vuelta
                opacity: view.sw.running ? 1 : 0.4
                onClicked: view.sw.lap()
            }
        }

        // Vueltas (alto fijo para que el panel no cambie de tamaño al marcar).
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            clip: true

            Text {
                anchors.centerIn: parent
                visible: view.sw.laps.length === 0
                text: "Sin vueltas"
                color: Theme.overlay0
                font { family: Theme.font; pixelSize: 12 }
            }

            ListView {
                anchors.fill: parent
                model: view.sw.laps
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                delegate: RowLayout {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    readonly property color c: modelData.lap === view.best ? Theme.green
                        : modelData.lap === view.worst ? Theme.red : Theme.subtext0
                    Text {
                        text: "#" + (view.sw.laps.length - index)
                        color: Theme.overlay1
                        font { family: Theme.font; pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: view.sw.fmt(modelData.lap)
                        color: parent.c
                        font { family: Theme.font; pixelSize: 12; weight: Font.Bold }
                    }
                    Text {
                        Layout.preferredWidth: 90
                        horizontalAlignment: Text.AlignRight
                        text: view.sw.fmt(modelData.total)
                        color: Theme.overlay1
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
            }
        }
    }
}
