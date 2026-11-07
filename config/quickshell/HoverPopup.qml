// Contenedor reutilizable: los hijos son el "botón" visible en la barra; al
// mantener el cursor encima `openDelay` ms se abre un PopupWindow con el
// componente `popup`. Sigue abierto mientras el cursor esté sobre el botón o
// sobre el panel; al salir se cierra tras una breve gracia. No usa Esc.
// Un clic en el botón también lo abre/cierra; `show()` lo abre por código y `close()` lo cierra por código (p. ej. tras elegir una opción).

import Quickshell
import QtQuick

Item {
    id: root

    default property alias content: slot.data
    property Component popup
    property int popupWidth: 280
    property int openDelay: 2000
    // ms que el cursor puede estar fuera (botón y panel) antes de cerrarse.
    property int closeDelay: 1000
    // Alto fijo de la ventana: redimensionar un popup de Wayland en vivo se
    // rompe, así que la ventana nunca cambia de tamaño y solo el panel visible
    // (con máscara de input) se ajusta al contenido.
    property int popupMaxHeight: 560
    // true: el panel nace en el borde izquierdo del botón y crece a la derecha
    // (para botones pegados al lado izquierdo de la barra).
    property bool alignLeft: false

    function close() { win.visible = false }
    function show() { win.visible = true }

    readonly property bool hovered: btnHover.hovered || panelHover.hovered
    readonly property bool open: win.visible

    Item { id: slot; anchors.fill: parent }

    HoverHandler { id: btnHover }
    TapHandler { onTapped: win.visible = !win.visible }   // clic: abre/cierra sin esperar

    Timer {
        interval: root.openDelay
        running: btnHover.hovered && !win.visible
        onTriggered: win.visible = true
    }
    Timer {
        interval: root.closeDelay   // gracia para cruzar del botón al panel
        running: win.visible && !root.hovered
        onTriggered: win.visible = false
    }

    PopupWindow {
        id: win
        visible: false
        anchor.item: root
        anchor.edges: root.alignLeft ? Edges.Bottom | Edges.Left : Edges.Bottom | Edges.Right
        anchor.gravity: root.alignLeft ? Edges.Bottom | Edges.Right : Edges.Bottom | Edges.Left
        implicitWidth: root.popupWidth
        implicitHeight: root.popupMaxHeight
        color: "transparent"
        mask: Region { item: panel }

        Rectangle {
            id: panel
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.topMargin: 10
            height: Math.min(loader.implicitHeight + 36, root.popupMaxHeight - 10)
            radius: 16
            color: Qt.alpha(Theme.base, 0.94)
            border.color: Qt.alpha(Theme.surface2, 0.6)
            border.width: 1

            HoverHandler { id: panelHover }

            Loader {
                id: loader
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                sourceComponent: root.popup
            }
        }
    }
}
