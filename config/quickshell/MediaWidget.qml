// Reproductor multimedia para el centro de la barra (MPRIS: Spotify, navegador,
// etc.). En la barra solo hay botones (anterior / play-pausa / siguiente) y un
// espectro falso (no analiza audio): su altura máxima sigue el volumen del sink
// por defecto y solo se mueve mientras algo suena. Un clic en el widget abre un
// panel con un CD que gira mientras suena (con la carátula), título, artista,
// álbum y barra de progreso.

import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Prefiere el player que está sonando; si no, el primero disponible.
    readonly property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying) return list[i]
        return list.length > 0 ? list[0] : null
    }
    readonly property bool hasPlayer: player !== null && label !== ""
    readonly property string label: {
        if (!player) return ""
        const t = player.trackTitle || ""
        const a = player.trackArtist || ""
        return a && t ? a + " — " + t : (t || a)
    }

    readonly property bool playing: player !== null && player.isPlaying
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    // 0..1; silenciado = 0 (barras planas).
    readonly property real volume: sink && sink.audio && !sink.audio.muted
        ? Math.min(1, sink.audio.volume) : 0

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36

    // Botón de control: icono con fondo al pasar el ratón.
    component CtrlButton: Item {
        id: btn
        property string icon
        property color iconColor: Theme.text
        property int size: 26
        property int glyph: Theme.iconSize
        signal activated()
        width: size
        height: size
        Rectangle {
            anchors.fill: parent
            radius: 7
            color: ma.containsMouse ? Theme.surface0 : "transparent"
        }
        Text {
            anchors.centerIn: parent
            text: btn.icon
            color: btn.iconColor
            font { family: Theme.font; pixelSize: btn.glyph }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.activated()
        }
    }

    // Clic en cualquier hueco (espectro incluido) abre/cierra el panel; los
    // botones quedan encima y consumen sus propios clics.
    MouseArea {
        anchors.fill: parent
        onClicked: win.visible = !win.visible
    }
    // Se cierra solo si el cursor lleva más de 1 s fuera del widget y del panel
    // (misma gracia que HoverPopup).
    HoverHandler { id: barHover }
    Timer {
        interval: 1000
        running: win.visible && !barHover.hovered && !panelHover.hovered
        onTriggered: win.visible = false
    }
    onHasPlayerChanged: if (!hasPlayer) win.visible = false

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // 󰒮 anterior
        CtrlButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "\u{f04ae}"
            iconColor: root.player && root.player.canGoPrevious ? Theme.text : Theme.overlay1
            onActivated: if (root.player) root.player.previous()
        }
        // 󰏤 pausa / 󰐊 play
        CtrlButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: root.playing ? "\u{f03e4}" : "\u{f040a}"
            iconColor: root.playing ? Theme.mauve : Theme.overlay1
            onActivated: if (root.player) root.player.togglePlaying()
        }
        // 󰒭 siguiente
        CtrlButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "\u{f04ad}"
            iconColor: root.player && root.player.canGoNext ? Theme.text : Theme.overlay1
            onActivated: if (root.player) root.player.next()
        }

        // Ecualizador artificial: un Timer lento reparte alturas aleatorias y
        // Behavior las suaviza; parado en pausa, sin coste.
        Row {
            id: eq
            anchors.verticalCenter: parent.verticalCenter
            height: 18
            spacing: 2
            Repeater {
                id: bars
                model: 9
                Rectangle {
                    id: bar
                    property real level: 0.2
                    anchors.bottom: parent.bottom
                    width: 3
                    radius: 1.5
                    color: root.playing ? Theme.mauve : Theme.overlay1
                    height: Math.max(3, eq.height * (root.playing ? level * root.volume : 0))
                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
            Timer {
                interval: 160
                repeat: true
                running: root.playing && root.volume > 0
                triggeredOnStart: true
                onTriggered: {
                    for (let i = 0; i < bars.count; i++)
                        bars.itemAt(i).level = 0.25 + Math.random() * 0.75
                }
            }
        }
    }

    // Metadatos extra de MPRIS (listas o textos según el player).
    function meta(key) {
        const v = player && player.metadata ? player.metadata[key] : undefined
        if (v === undefined || v === null) return ""
        return Array.isArray(v) ? v.join(", ") : String(v)
    }
    readonly property var details: {
        if (!player) return []
        const out = []
        const add = (k, v) => { if (v) out.push({ k: k, v: v }) }
        add("Álbum", player.trackAlbum)
        add("Artista del álbum", meta("xesam:albumArtist") !== player.trackArtist ? meta("xesam:albumArtist") : "")
        const tn = meta("xesam:trackNumber"), dn = meta("xesam:discNumber")
        add("Pista", tn && tn !== "0" ? (dn && dn !== "0" && dn !== "1" ? "Disco " + dn + " · " : "") + "nº " + tn : "")
        add("Género", meta("xesam:genre"))
        add("Año", meta("xesam:contentCreated").substring(0, 4))
        add("Compositor", meta("xesam:composer"))
        add("Fuente", player.identity)
        return out
    }

    // Panel desplegable. Ventana de tamaño fijo (redimensionar un popup de
    // Wayland en vivo se rompe); el input se limita al panel con la máscara.
    PopupWindow {
        id: win
        visible: false
        anchor.item: root
        // Nace en el borde izquierdo del widget y crece hacia la derecha.
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        implicitWidth: 640
        implicitHeight: 400
        color: "transparent"
        mask: Region { item: panel }

        Rectangle {
            id: panel
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.topMargin: 10
            height: Math.max(body.implicitHeight, info.implicitHeight) + 40
            radius: 20
            color: Qt.alpha(Theme.base, 0.95)
            border.color: Qt.alpha(Theme.surface2, 0.6)
            border.width: 1

            HoverHandler { id: panelHover }

            // Posición: MPRIS no avisa de cada segundo, se consulta mientras suena.
            Timer {
                interval: 500
                repeat: true
                running: win.visible && root.playing
                onTriggered: if (root.player) root.player.positionChanged()
            }

            Row {
                id: body
                anchors { fill: parent; margins: 20 }
                spacing: 26

                // CD
                Item {
                    id: cd
                    anchors.verticalCenter: parent.verticalCenter
                    width: 210
                    height: 210
                    readonly property url art: root.player ? root.player.trackArtUrl : ""

                    // Máscara circular (invisible, solo para recortar la carátula)
                    Rectangle {
                        id: discMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        layer.enabled: true
                    }

                    // Brillo ambiental detrás del disco
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 14
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 7
                        border.color: Qt.alpha(Theme.mauve, root.playing ? 0.18 : 0.06)
                        Behavior on border.color { ColorAnimation { duration: 300 } }
                    }

                    // Disco que gira (se detiene en pausa conservando el ángulo)
                    Item {
                        id: disc
                        anchors.fill: parent

                        // Una vuelta cada 7 s; en pausa conserva el ángulo.
                        FrameAnimation {
                            running: win.visible && root.playing
                            onTriggered: disc.rotation = (disc.rotation + frameTime * 360 / 7) % 360
                        }

                        // Cara del CD cuando no hay carátula
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.surface1 }
                                GradientStop { position: 1; color: Theme.mauve }
                            }
                        }
                        Image {
                            id: artImg
                            anchors.fill: parent
                            source: cd.art
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                            layer.enabled: true
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: artImg
                            maskEnabled: true
                            maskSource: discMask
                            visible: artImg.status === Image.Ready
                        }
                        // Surcos del disco
                        Repeater {
                            model: 3
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 28 - index * 34
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: Qt.alpha(Theme.crust, 0.25)
                            }
                        }
                        // Brillo fijo del plástico (gira con el disco, da sensación de giro)
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.alpha(Theme.text, 0.12)
                        }
                        // Anillo y agujero central
                        Rectangle {
                            anchors.centerIn: parent
                            width: 58
                            height: 58
                            radius: 29
                            color: Qt.alpha(Theme.surface0, 0.85)
                            border.width: 2
                            border.color: Qt.alpha(Theme.text, 0.2)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 12
                            color: Theme.base
                            border.width: 2
                            border.color: Qt.alpha(Theme.overlay1, 0.6)
                        }
                    }
                }


                // Información a la derecha
                Column {
                    id: info
                    anchors.verticalCenter: parent.verticalCenter
                    width: body.width - cd.width - body.spacing
                    spacing: 14

                    // Estado + fuente
                    Row {
                        spacing: 6
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10; height: 10; radius: 5
                            color: root.playing ? Theme.ok : Theme.overlay1
                        }
                        Text {
                            text: (root.playing ? "Reproduciendo" : "En pausa") + (root.player && root.player.identity ? " · " + root.player.identity : "")
                            color: Theme.overlay1
                            font { family: Theme.font; pixelSize: 13 }
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: root.player ? (root.player.trackTitle || "Sin título") : ""
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 22; weight: Font.Bold }
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.player ? root.player.trackArtist : ""
                        visible: text !== ""
                        color: Theme.mauve
                        font { family: Theme.font; pixelSize: 16 }
                    }

                    // Detalles clave/valor (solo los que existan)
                    Column {
                        width: parent.width
                        spacing: 5
                        Repeater {
                            model: root.details
                            Row {
                                required property var modelData
                                spacing: 8
                                Text {
                                    width: 125
                                    text: modelData.k
                                    color: Theme.overlay1
                                    font { family: Theme.font; pixelSize: 13 }
                                }
                                Text {
                                    width: info.width - 133
                                    elide: Text.ElideRight
                                    text: modelData.v
                                    color: Theme.subtext0
                                    font { family: Theme.font; pixelSize: 13 }
                                }
                            }
                        }
                    }

                    // Progreso (clic o arrastre para saltar si el player lo permite)
                    Item {
                        id: progress
                        width: parent.width
                        height: 38
                        readonly property real len: root.player ? root.player.length : 0
                        readonly property real pos: root.player ? root.player.position : 0
                        readonly property real frac: Math.min(1, pos / Math.max(1, len))
                        visible: len > 0

                        function fmt(t) {
                            const s = Math.max(0, Math.floor(t))
                            return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
                        }

                        Rectangle {
                            id: pTrack
                            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 6 }
                            height: 8
                            radius: 4
                            color: Theme.surface1
                            Rectangle {
                                width: parent.width * progress.frac
                                height: parent.height
                                radius: 4
                                color: Theme.mauve
                            }
                        }
                        Rectangle {
                            x: progress.frac * (pTrack.width - width)
                            y: pTrack.y + pTrack.height / 2 - height / 2
                            width: 16; height: 16; radius: 8
                            color: Theme.text
                        }
                        MouseArea {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 24
                            enabled: root.player && root.player.canSeek && root.player.positionSupported
                            function seek(mx) { root.player.position = progress.len * Math.max(0, Math.min(1, mx / width)) }
                            onPressed: mouse => seek(mouse.x)
                            onPositionChanged: mouse => { if (pressed) seek(mouse.x) }
                        }
                        Text {
                            anchors { left: parent.left; bottom: parent.bottom }
                            text: progress.fmt(progress.pos)
                            color: Theme.subtext0
                            font { family: Theme.font; pixelSize: 13 }
                        }
                        Text {
                            anchors { right: parent.right; bottom: parent.bottom }
                            text: progress.fmt(progress.len)
                            color: Theme.subtext0
                            font { family: Theme.font; pixelSize: 13 }
                        }
                    }

                    // Controles: aleatorio, anterior, play, siguiente, repetir
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        CtrlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 36; glyph: 22
                            visible: root.player && root.player.shuffleSupported
                            icon: "\u{f049d}"
                            iconColor: root.player && root.player.shuffle ? Theme.mauve : Theme.overlay1
                            onActivated: root.player.shuffle = !root.player.shuffle
                        }
                        CtrlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 36; glyph: 22
                            icon: "\u{f04ae}"
                            iconColor: root.player && root.player.canGoPrevious ? Theme.text : Theme.overlay1
                            onActivated: if (root.player) root.player.previous()
                        }
                        CtrlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 48; glyph: 30
                            icon: root.playing ? "\u{f03e4}" : "\u{f040a}"
                            iconColor: Theme.mauve
                            onActivated: if (root.player) root.player.togglePlaying()
                        }
                        CtrlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 36; glyph: 22
                            icon: "\u{f04ad}"
                            iconColor: root.player && root.player.canGoNext ? Theme.text : Theme.overlay1
                            onActivated: if (root.player) root.player.next()
                        }
                        CtrlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 36; glyph: 22
                            visible: root.player && root.player.loopSupported
                            icon: root.player && root.player.loopState === MprisLoopState.Track ? "\u{f0458}" : "\u{f0456}"
                            iconColor: root.player && root.player.loopState !== MprisLoopState.None ? Theme.mauve : Theme.overlay1
                            onActivated: root.player.loopState =
                                root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                                : MprisLoopState.None
                        }
                    }

                    // Volumen del player (si lo expone)
                    Row {
                        visible: root.player && root.player.volumeSupported
                        spacing: 12
                        width: parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{f057e}"
                            color: Theme.subtext0
                            font { family: Theme.font; pixelSize: 22 }
                        }
                        Item {
                            id: vSlider
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 100
                            height: 24
                            readonly property real frac: Math.min(1, root.player ? root.player.volume : 0)
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                height: 8; radius: 4
                                color: Theme.surface1
                                Rectangle {
                                    width: parent.width * vSlider.frac
                                    height: parent.height; radius: 4
                                    color: Theme.lavender
                                }
                            }
                            Rectangle {
                                x: vSlider.frac * (parent.width - width)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16; height: 16; radius: 8
                                color: Theme.text
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: mouse => root.player.volume = Math.max(0, Math.min(1, mouse.x / width))
                                onPositionChanged: mouse => { if (pressed) root.player.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(vSlider.frac * 100) + "%"
                            color: Theme.subtext0
                            font { family: Theme.font; pixelSize: 13 }
                        }
                    }
                }
            }
        }
    }
}
