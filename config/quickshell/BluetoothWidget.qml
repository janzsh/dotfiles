// Indicador de Bluetooth para la barra (Quickshell.Bluetooth / BlueZ).
// Hover de 2 s / clic abre un panel: encendido, escaneo y lista de
// dispositivos (clic = conectar/desconectar; los no emparejados se emparejan).
//
// Emparejar NO se hace con device.pair() a secas (sin agente por defecto BlueZ
// rechaza con "Authentication Failed" en mouses/teclados genéricos). Se abre
// una sesión de bluetoothctl y se sigue, reaccionando a su salida, la misma
// secuencia que funciona a mano:
//   scan off -> power on, agent on, default-agent, pairable on
//   -> scan on y ESPERAR el [NEW]/[CHG] del dispositivo (evita "not available")
//   -> trust -> pair -> connect -> scan off, quit
// Si el escaneo da org.bluez.Error.InProgress se hace scan off y se reintenta.

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled
    readonly property var connectedDevs: adapter
        ? adapter.devices.values.filter(d => d.connected) : []

    implicitWidth: 34
    implicitHeight: 36
    popupWidth: 300

    // ---------- emparejamiento robusto (estado fuera del popup) ----------
    property string pairAddr: ""
    // idle | agent | scan | trust | pair | connect | failed
    property string pairStep: "idle"
    property string pairMsg: ""
    readonly property bool pairBusy: pairStep !== "idle" && pairStep !== "failed"

    readonly property var stepLabel: ({
        agent: "preparando…", scan: "buscando…", trust: "confiando…",
        pair: "emparejando…", connect: "conectando…"
    })

    function sameAddr(line) { return line.toUpperCase().indexOf(pairAddr.toUpperCase()) >= 0 }
    function send(cmd) { ctl.write(cmd + "\n") }

    function startPair(addr) {
        if (pairBusy || !adapter) return
        pairAddr = addr
        pairMsg = ""
        pairStep = "agent"
        adapter.discovering = false          // libera un escaneo previo colgado
        overall.restart()
        if (ctl.running) setupSession()      // si no, onStarted lo hace
        else ctl.running = true
    }
    // scan off, hardware y agente por defecto ANTES de escanear.
    function setupSession() {
        send("scan off")
        send("power on")
        send("agent on")
        send("default-agent")
        send("pairable on")
        agentFallback.restart()              // por si no llega la confirmación
    }
    function toScan() {
        if (pairStep !== "agent") return
        agentFallback.stop()
        pairStep = "scan"
        send("scan on")
    }
    // Solo tras ver el dispositivo en el escaneo actual se manda trust.
    function toTrust() {
        pairStep = "trust"
        send("trust " + pairAddr)
    }
    function toPair() { pairStep = "pair"; send("pair " + pairAddr) }
    function toConnect() { pairStep = "connect"; send("connect " + pairAddr) }
    function finishPair(ok, msg) {
        overall.stop(); agentFallback.stop(); retryScan.stop()
        send("scan off")
        send("quit")                         // al salir se libera el agente
        pairMsg = msg
        pairStep = ok ? "idle" : "failed"
        if (!ok) clearFail.restart()
        pairAddr = ok ? "" : pairAddr
    }

    function onCtlLine(raw) {
        // quita colores ANSI, retornos de carro y el prompt de bluetoothctl
        const line = raw.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").replace(/\r/g, "")
                        .replace(/\[[^\]]*\][>#]\s*/g, "").trim()
        if (line === "" || !pairBusy) return

        // Escaneo ocupado por otro cliente: apagar y reintentar.
        if (/InProgress|Operation already in progress/i.test(line) && pairStep === "scan") {
            send("scan off")
            retryScan.restart()
            return
        }
        switch (pairStep) {
        case "agent":
            if (/Default agent request successful|Agent registered|already registered|AlreadyExists|already exists/i.test(line)) toScan()
            break
        case "scan":
            if (/\[(NEW|CHG)\] Device/i.test(line) && sameAddr(line)) toTrust()
            break
        case "trust":
            if (/trust succeeded/i.test(line)) toPair()
            else if (/not available/i.test(line)) { pairStep = "scan"; send("scan on") }  // aún no indexado
            else if (/Failed to (set )?trust/i.test(line)) finishPair(false, "No se pudo confiar")
            break
        case "pair":
            if (/Pairing successful|AlreadyExists|Already Exists/i.test(line)) toConnect()
            else if (/Failed to pair|AuthenticationFailed|Authentication (Failed|Rejected)|not available/i.test(line))
                finishPair(false, "Falló el emparejamiento")
            break
        case "connect":
            if (/Connection successful/i.test(line)) finishPair(true, "")
            else if (/Failed to connect|not available/i.test(line)) finishPair(false, "No se pudo conectar")
            break
        }
    }

    Process {
        id: ctl
        command: ["bluetoothctl"]
        stdinEnabled: true
        onStarted: root.setupSession()
        stdout: SplitParser { onRead: line => root.onCtlLine(line) }
        onExited: if (root.pairBusy) root.finishPair(false, "bluetoothctl se cerró")
    }
    // Sin confirmación del agente en 3 s se sigue igual.
    Timer { id: agentFallback; interval: 3000; onTriggered: root.toScan() }
    // Reintento de "scan on" tras InProgress (el bus tarda en quedar libre).
    Timer { id: retryScan; interval: 700; onTriggered: if (root.pairStep === "scan") root.send("scan on") }
    Timer { id: overall; interval: 45000; onTriggered: if (root.pairBusy) root.finishPair(false, "Tiempo agotado") }
    Timer { id: clearFail; interval: 4000; onTriggered: { root.pairStep = "idle"; root.pairAddr = "" } }

    // Buscar desde el panel: apagar primero cualquier escaneo previo (si otro
    // cliente lo dejó activo, StartDiscovery daría InProgress).
    function toggleScan() {
        if (!adapter) return
        if (adapter.discovering) { adapter.discovering = false; return }
        adapter.discovering = false
        scanStart.restart()
    }
    Timer { id: scanStart; interval: 500; onTriggered: if (root.adapter) root.adapter.discovering = true }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.hovered ? Theme.surface0 : "transparent"
    }
    Text {
        anchors.centerIn: parent
        text: !root.on ? "󰂲" : root.connectedDevs.length > 0 ? "󰂱" : "󰂯"
        color: !root.on ? Theme.overlay0 : root.connectedDevs.length > 0 ? Theme.pink : Theme.mauve
        font { family: Theme.font; pixelSize: Theme.iconSize }
    }

    // Detener el escaneo al cerrar el panel (gasta batería).
    // (no mientras se empareja: esa sesión maneja su propio escaneo).
    onOpenChanged: if (!open && adapter && !pairBusy) adapter.discovering = false

    popup: Component {
        ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Bluetooth"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 14; weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                // Interruptor encendido/apagado
                Rectangle {
                    width: 40; height: 22; radius: 11
                    color: root.on ? Theme.mauve : Theme.surface1
                    Rectangle {
                        y: 3; width: 16; height: 16; radius: 8
                        x: root.on ? 21 : 3
                        color: Theme.crust
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.adapter !== null
                        onClicked: root.adapter.enabled = !root.adapter.enabled
                    }
                }
            }

            Text {
                visible: root.adapter === null
                text: "Sin adaptador Bluetooth"
                color: Theme.subtext0
                font { family: Theme.font; pixelSize: 12 }
            }

            // Escanear
            Rectangle {
                visible: root.on
                Layout.fillWidth: true
                height: 32
                radius: 10
                color: scanMa.containsMouse ? Theme.surface1 : Theme.surface0
                Text {
                    anchors.centerIn: parent
                    text: root.adapter && root.adapter.discovering ? "Buscando… (clic para parar)" : "Buscar dispositivos"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 12; weight: Font.Bold }
                }
                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleScan()
                }
            }

            // Lista de altura fija (máx. 6 filas, luego scroll): así el panel no
            // se estira mientras el escaneo va descubriendo dispositivos.
            ListView {
                id: list
                visible: root.on
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 6 * 44)
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                // Solo con nombre; conectados primero, luego guardados, luego nuevos.
                model: ScriptModel {
                    values: root.on
                        ? root.adapter.devices.values
                            .filter(d => d.name !== "" && d.name !== d.address)
                            .sort((x, y) => (y.connected - x.connected) || (y.paired - x.paired)
                                || x.name.localeCompare(y.name))
                        : []
                }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: list.width
                    height: 40
                    radius: 10
                    color: devMa.containsMouse ? Theme.surface1 : Theme.surface0

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: row.modelData.name
                            color: row.modelData.connected ? Theme.pink : Theme.text
                            font { family: Theme.font; pixelSize: 12; weight: row.modelData.connected ? Font.Bold : Font.Normal }
                        }
                        Text {
                            visible: row.modelData.connected && row.modelData.batteryAvailable
                            text: Math.round(row.modelData.battery * 100) + "%"
                            color: Theme.subtext0
                            font { family: Theme.font; pixelSize: 11 }
                        }
                        Text {
                            readonly property bool mine: root.pairAddr === row.modelData.address
                            text: mine && root.pairBusy ? root.stepLabel[root.pairStep]
                                : mine && root.pairStep === "failed" ? root.pairMsg
                                : row.modelData.pairing ? "emparejando…"
                                : row.modelData.connected ? "conectado"
                                : row.modelData.paired ? "guardado" : "nuevo"
                            color: Theme.subtext0
                            font { family: Theme.font; pixelSize: 11 }
                        }
                    }
                    MouseArea {
                        id: devMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const d = row.modelData
                            if (root.pairBusy) return
                            if (d.connected) d.disconnect()
                            else if (d.paired) { d.trusted = true; d.connect() }
                            else root.startPair(d.address)
                        }
                    }
                }
            }
        }
    }
}
