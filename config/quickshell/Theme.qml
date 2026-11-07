// Paleta compartida por todo el shell. Se usa como `Theme.mauve`, `Theme.base`, etc.
//
// Los valores de abajo son solo el respaldo (Evernight). El tema real lo escribe
// `config/theme/bin/theme` en ~/.cache/theme/theme.json y este singleton lo
// vigila: `theme set <nombre>` recolorea toda la barra en vivo, sin reiniciar.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string name: "evernight"

    property color rosewater: "#f5d5e0"
    property color flamingo: "#f2b5cf"
    property color pink: "#f09ac8"
    property color mauve: "#c58af0"
    property color mauvePastel: "#e3d0f7"
    property color red: "#f0475f"
    property color peach: "#f2a07b"
    property color yellow: "#efc46a"
    property color green: "#8fd9a8"
    // Estado "bien/activo" de la interfaz (carga baja, reproduciendo). Cada tema lo define.
    property color ok: "#8fe3f0"
    property color teal: "#7fd6d0"
    property color sky: "#8ec8f5"
    property color blue: "#8aa4f5"
    property color lavender: "#b9b3f7"
    property color text: "#e9e4f7"
    property color subtext1: "#d0cbe6"
    property color subtext0: "#b3aed0"
    property color overlay2: "#9a95bb"
    property color overlay1: "#827ea3"
    property color overlay0: "#6b6889"
    property color surface2: "#4f4c6e"
    property color surface1: "#3a3957"
    property color surface0: "#2a2a45"
    property color base: "#181c33"
    property color mantle: "#121528"
    property color crust: "#0c0e1e"

    // Tamaños de la barra: todos los iconos iguales, todo el texto igual.
    readonly property int iconSize: 18
    readonly property int barText: 13

    readonly property string font: "JetBrainsMono Nerd Font"

    readonly property var colorNames: [
        "rosewater", "flamingo", "pink", "mauve", "mauvePastel", "red", "peach", "yellow", "green", "ok", "teal", "sky", "blue", "lavender", "text", "subtext1", "subtext0", "overlay2", "overlay1", "overlay0", "surface2", "surface1", "surface0", "base", "mantle", "crust"
    ]

    function apply(txt) {
        try {
            const t = JSON.parse(txt)
            for (const k of colorNames)
                if (t.colors && t.colors[k]) root[k] = t.colors[k]
            if (t.name) name = t.name
        } catch (e) {
            // archivo a medias o ilegible: se conserva la paleta anterior
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/theme/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
}
