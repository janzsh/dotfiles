// Dock inferior: una píldora con un icono por app abierta en el workspace
// actual (lista `apps` de wm-state-bridge.sh). Clic en el icono enfoca la app.
//
// En Hyprland es fijo: se ve mientras haya al menos una ventana y se dibuja
// sobre ellas, sin reservar espacio; empieza escondido y, tras 10 s sin el
// cursor encima, se esconde otra vez (vuelve al pasar por el borde de abajo o
// al cambiar las apps). En otros compositores (sway) se
// mantiene el modo hover: una franja de 3px en el borde; al pasar el cursor sube
// la píldora.
//
// Son dos ventanas layer-shell: la franja (fija, siempre la misma región de
// entrada) y el dock (solo existe mientras está revelado). Separarlas evita el
// bucle enter/leave que daba cambiar la máscara de entrada con el cursor encima.

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

Scope {
    id: root

    // [{app, id, count, focused}] del workspace enfocado
    property var apps: []

    readonly property bool persistent: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""

    readonly property int iconBox: 34
    readonly property int iconSize: 24
    readonly property int pad: 6
    readonly property int edge: 14       // separación del dock al borde inferior
    readonly property int stripWidth: 640
    readonly property int stripHeight: 3

    property bool revealed: false
    // Fijo (Hyprland): empieza oculto; se oculta tras `idleMs` sin el cursor encima y vuelve al
    // pasar el cursor por el borde de abajo o al cambiar las apps/el foco.
    property bool idleHidden: true
    readonly property int idleMs: 5000
    readonly property bool shown: apps.length > 0 && (revealed || (persistent && !idleHidden))

    Timer { id: idleTimer; interval: root.idleMs; onTriggered: root.idleHidden = true }

    property string appsSig: ""
    onAppsChanged: {
        const sig = JSON.stringify(apps)
        const first = appsSig === ""
        if (sig === appsSig) return
        appsSig = sig
        if (first) return   // arranque: empieza escondido
        idleHidden = false
        if (persistent) idleTimer.restart()
    }

    function reveal() {
        if (persistent) { idleHidden = false; idleTimer.restart(); return }
        revealed = true; hideTimer.interval = 900; hideTimer.restart()
    }
    function dismiss() { hideTimer.stop(); revealed = false }

    // Si el cursor sale de la franja sin llegar al dock, se esconde solo.
    Timer { id: hideTimer; interval: 900; onTriggered: root.revealed = false }

    function iconFor(app) {
        const e = DesktopEntries.heuristicLookup(app)
        return Quickshell.iconPath(e ? e.icon : app.toLowerCase(), "application-x-executable")
    }

    // Zona de activación
    PanelWindow {
        visible: root.apps.length > 0 && (!root.persistent || root.idleHidden)
        color: "transparent"
        anchors { bottom: true }
        implicitWidth: root.stripWidth
        implicitHeight: root.stripHeight
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qs-dock-trigger"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onContainsMouseChanged: { if (containsMouse && root.apps.length > 0) root.reveal() }
        }
    }

    PanelWindow {
        id: win
        visible: root.apps.length > 0
        color: "transparent"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: root.iconBox + root.pad * 2 + root.edge + (root.persistent ? 0 : 12)
        // Flota sobre las ventanas: no reserva espacio.
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qs-dock"

        // Solo el dock (y su margen) recibe el ratón cuando está revelado; el resto
        // (y todo, mientras está oculto) pasa a lo que haya debajo.
        mask: root.shown ? hitMask : emptyMask
        Region { id: hitMask; item: hit }
        Region { id: emptyMask }

        Item {
            id: hit
            width: dock.width + 24
            height: win.height
            x: (win.width - width) / 2
            y: 0
            // Pasivo: sigue viendo el cursor aunque un icono (MouseArea) esté encima.
            HoverHandler {
                onHoveredChanged: {
                    if (root.persistent) {
                        if (hovered) idleTimer.stop()
                        else idleTimer.restart()
                        return
                    }
                    if (hovered) hideTimer.stop()
                    else if (root.revealed) { hideTimer.interval = 350; hideTimer.restart() }
                }
            }

            Rectangle {
                id: dock
                width: row.width + root.pad * 2
                height: root.iconBox + root.pad * 2
                radius: 18
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.shown ? hit.height - height - root.edge : hit.height + 4
                opacity: root.shown ? 1 : 0
                color: Qt.alpha(Theme.crust, 0.78)
                border.width: 1
                border.color: Qt.alpha(Theme.surface1, 0.55)

                Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Row {
                    id: row
                    x: root.pad; y: root.pad
                    spacing: 4

                    Repeater {
                        model: root.apps

                        Rectangle {
                            id: cell
                            required property var modelData
                            width: root.iconBox; height: root.iconBox
                            radius: 13
                            color: ma.containsMouse ? Qt.alpha(Theme.surface1, 0.9)
                                 : modelData.focused ? Qt.alpha(Theme.surface0, 0.9) : "transparent"

                            IconImage {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: cell.modelData.count > 1 ? -3 : 0
                                implicitSize: root.iconSize
                                source: root.iconFor(cell.modelData.app)
                            }
                            // Bajo la app: con 2+ instancias, su número; con una sola,
                            // un punto si es la enfocada.
                            Text {
                                visible: cell.modelData.count > 1
                                text: cell.modelData.count
                                color: cell.modelData.focused ? Theme.mauve : Theme.subtext0
                                font { family: Theme.font; pixelSize: 10; weight: Font.Bold }
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -1 }
                            }
                            Rectangle {
                                visible: cell.modelData.focused && cell.modelData.count <= 1
                                width: 4; height: 4; radius: 2
                                color: Theme.mauve
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.shellDir + "/wmctl.sh", "focus", String(cell.modelData.id)])
                                    root.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
