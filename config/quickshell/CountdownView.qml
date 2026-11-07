// Página "Temporizador" del carrusel. Solo dibuja; el estado vive en
// Countdown.qml (`cd`). Parado: ▲▼ por cifra y atajos; corriendo: tiempo grande
// y barra de progreso. `pomo` solo aporta la lista de sonidos y la vista previa.

import QtQuick
import QtQuick.Layouts

Item {
    id: view

    required property var cd
    required property var pomo

    implicitHeight: col.implicitHeight
    readonly property bool idle: !view.cd.running && view.cd.remaining === view.cd.presetSec

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 14

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Temporizador"
            color: Theme.ok
            font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
        }

        // Parado: horas / minutos / segundos editables.
        Row {
            visible: view.idle
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Repeater {
                model: [
                    { unit: 3600, label: "h" },
                    { unit: 60,   label: "min" },
                    { unit: 1,    label: "s" }
                ]
                Column {
                    id: dig
                    required property var modelData
                    required property int index
                    spacing: 4
                    readonly property int val: Math.floor(view.cd.presetSec / modelData.unit) % (modelData.unit === 3600 ? 100 : 60)
                    IconButton { anchors.horizontalCenter: parent.horizontalCenter; size: 30; iconSize: 14
                                 icon: "\u{f0143}"; onClicked: view.cd.adjust(dig.modelData.unit) }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (dig.val < 10 ? "0" : "") + dig.val
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 44; weight: Font.Bold }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dig.modelData.label
                        color: Theme.overlay1
                        font { family: Theme.font; pixelSize: 11 }
                    }
                    IconButton { anchors.horizontalCenter: parent.horizontalCenter; size: 30; iconSize: 14
                                 icon: "\u{f0140}"; onClicked: view.cd.adjust(-dig.modelData.unit) }
                }
            }
        }

        // En curso o pausado: tiempo restante + progreso.
        ColumnLayout {
            visible: !view.idle
            Layout.fillWidth: true
            spacing: 14
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: view.cd.fmt(view.cd.remaining)
                color: view.cd.running ? Theme.text : Theme.overlay1
                font { family: Theme.font; pixelSize: 56; weight: Font.Bold }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 6; radius: 3
                color: Theme.surface0
                Rectangle {
                    width: parent.width * (view.cd.presetSec > 0 ? view.cd.remaining / view.cd.presetSec : 0)
                    height: parent.height; radius: 3
                    color: Theme.ok
                }
            }
        }

        // Atajos (solo parado).
        Row {
            visible: view.idle
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: [60, 300, 600, 900, 1800]
                Rectangle {
                    id: chip
                    required property int modelData
                    width: 52; height: 28; radius: 9
                    color: view.cd.presetSec === modelData ? Theme.ok
                         : cma.containsMouse ? Theme.surface1 : Theme.surface0
                    Text {
                        anchors.centerIn: parent
                        text: chip.modelData / 60 + " min"
                        color: view.cd.presetSec === chip.modelData ? Theme.crust : Theme.text
                        font { family: Theme.font; pixelSize: 11 }
                    }
                    MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: view.cd.setPreset(chip.modelData) }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            IconButton { size: 40; iconSize: 18; icon: "\u{f0450}"; onClicked: view.cd.reset() }
            IconButton {
                size: 56; iconSize: 26; filled: true; accent: Theme.ok
                icon: view.cd.running ? "\u{f03e4}" : "\u{f040a}"
                onClicked: view.cd.toggle()
            }
        }

        SoundPicker {
            Layout.fillWidth: true
            label: "Tono"
            accent: Theme.ok
            value: view.cd.sound
            choices: view.pomo.choices(false)
            onPicked: path => { view.cd.sound = path; view.cd.save() }
            onPreview: path => view.pomo.preview(path, 1.0)
        }
    }
}
