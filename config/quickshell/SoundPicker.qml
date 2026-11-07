// Selector de sonido compacto: etiqueta ‹ nombre › ▶ (probar).
// `choices` = [{name, path}]; al cambiar emite picked(path) y preview(path).
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: p

    property string label: ""
    property string value: ""
    property var choices: []
    property color accent: Theme.yellow
    signal picked(string path)
    signal preview(string path)

    readonly property int idx: {
        const i = choices.findIndex(c => c.path === value)
        return i < 0 ? 0 : i
    }
    function step(d) {
        if (choices.length === 0) return
        const c = choices[(idx + d + choices.length) % choices.length]
        picked(c.path)
        preview(c.path)
    }

    spacing: 6

    Rectangle { width: 4; height: 18; radius: 2; color: p.accent }
    Text {
        text: p.label
        color: Theme.subtext0
        font { family: Theme.font; pixelSize: 12 }
    }
    Item { Layout.fillWidth: true }
    IconButton { size: 28; iconSize: 14; icon: "\u{f0141}"; onClicked: p.step(-1) }
    Text {
        Layout.preferredWidth: 96
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: p.choices.length > 0 ? p.choices[p.idx].name : "—"
        color: p.accent
        font { family: Theme.font; pixelSize: 12; weight: Font.Bold }
    }
    IconButton { size: 28; iconSize: 14; icon: "\u{f0142}"; onClicked: p.step(1) }
    IconButton { size: 28; iconSize: 14; icon: "\u{f040a}"; onClicked: p.preview(p.value) }
}
