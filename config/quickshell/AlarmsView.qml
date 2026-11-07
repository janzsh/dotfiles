// Página "Alarma" del carrusel: lista de alarmas con interruptor; clic en una
// la edita, "+" crea otra. Estado y editor en Alarms.qml (`al`). `pomo` solo
// aporta la lista de sonidos y la vista previa.

import QtQuick
import QtQuick.Layouts

Item {
    id: view

    required property var al
    required property var pomo
    signal editRequested(int idx)

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Alarmas"
                color: Theme.yellow
                font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
            }
            Item { Layout.fillWidth: true }
            Text {
                // se recalcula al abrir el panel o al cambiar la lista
                text: { view.al.list; return view.al.nextText() }
                color: Theme.overlay1
                font { family: Theme.font; pixelSize: 11 }
            }
            IconButton { size: 30; iconSize: 15; icon: "\u{f0415}"; onClicked: view.editRequested(-1) }
        }

        Text {
            visible: view.al.list.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            Layout.bottomMargin: 24
            text: "Sin alarmas. Pulsa + para crear una."
            color: Theme.overlay1
            font { family: Theme.font; pixelSize: 12 }
        }

        Repeater {
            model: view.al.list
            Rectangle {
                id: row
                required property var modelData
                required property int index
                Layout.fillWidth: true
                height: 58
                radius: 12
                color: rma.containsMouse ? Theme.surface1 : Theme.surface0
                opacity: modelData.on ? 1 : 0.55

                MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: view.editRequested(row.index) }

                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    spacing: 12
                    Text {
                        text: view.al.timeText(row.modelData)
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 26; weight: Font.Bold }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: view.al.daysText(row.modelData)
                        elide: Text.ElideRight
                        color: Theme.subtext0
                        font { family: Theme.font; pixelSize: 12 }
                    }
                    // Interruptor
                    Rectangle {
                        width: 42; height: 24; radius: 12
                        color: row.modelData.on ? Theme.yellow : Theme.surface2
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            y: 3
                            x: row.modelData.on ? parent.width - width - 3 : 3
                            color: row.modelData.on ? Theme.crust : Theme.overlay1
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: view.al.toggle(row.index) }
                    }
                }
            }
        }

        SoundPicker {
            Layout.fillWidth: true
            Layout.topMargin: 4
            label: "Tono"
            accent: Theme.yellow
            value: view.al.sound
            choices: view.pomo.choices(false)
            onPicked: path => { view.al.sound = path; view.al.save() }
            onPreview: path => view.pomo.preview(path, 1.0)
        }
    }
}
