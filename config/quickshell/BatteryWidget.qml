// Indicador de batería horizontal para la barra. Con hover de 2 s (ver
// HoverPopup) abre un panel con datos de batería/consumo y botones de
// perfil de energía.

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

HoverPopup {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev.percentage * 100   // Quickshell: 0..1
    // El kernel a veces reporta "Not charging" (UPower: PendingCharge) estando
    // desenchufada. Por eso "conectada" se decide con el adaptador (onBattery),
    // y solo cuenta como cargando si además el estado es Charging.
    readonly property bool plugged: !UPower.onBattery
    readonly property bool charging: plugged && dev.state === UPowerDeviceState.Charging

    // Franjas de color: [límite superior, normal, cargando (más intenso)].
    // Tonos bien separados para distinguir el nivel de un vistazo: rojo
    // (crítico) -> durazno -> amarillo -> verde -> casi blanco al llegar a
    // ~100 % (aviso de que ya no conviene seguir cargando).
    readonly property var bands: [
        [20,  Theme.red,    Qt.lighter(Theme.red, 1.25)],     // 0-20   rojo
        [40,  Theme.peach,  Qt.lighter(Theme.peach, 1.2)],    // 21-40  durazno
        [60,  Theme.yellow, Qt.lighter(Theme.yellow, 1.2)],   // 41-60  amarillo
        [90,  Theme.green,  Qt.lighter(Theme.green, 1.2)],    // 61-90  verde
        [100, Theme.text,   "#ffffff"]                        // 91-100 casi blanco
    ]
    readonly property var band: {
        const p = Math.round(pct)
        for (let i = 0; i < bands.length; i++)
            if (p <= bands[i][0]) return bands[i]
        return bands[bands.length - 1]
    }
    readonly property color levelColor: charging ? band[2] : band[1]



    implicitWidth: row.implicitWidth + 24
    implicitHeight: 36
    popupWidth: 300

    function fmtTime(sec) {
        if (sec <= 0) return "—"
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.hovered ? Theme.surface0 : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // Batería dibujada en horizontal: cuerpo + relleno + borne.
        Item {
            width: 38; height: 18
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: body
                width: 34; height: parent.height
                radius: 5
                color: "transparent"
                border.width: 1.5
                border.color: Qt.alpha(root.levelColor, 0.85)

                Rectangle {
                    x: 3; y: 3
                    height: parent.height - 6
                    width: Math.max(3, (parent.width - 6) * Math.min(1, root.pct / 100))
                    radius: 2.5
                    color: root.levelColor
                    Behavior on width { NumberAnimation { duration: 200 } }
                }

                Text {
                    visible: root.charging
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF140B)
                    color: Theme.text
                    style: Text.Outline
                    styleColor: Theme.crust
                    font { family: Theme.font; pixelSize: 13 }
                }
            }
            Rectangle {
                x: 35; width: 3; height: 7
                anchors.verticalCenter: body.verticalCenter
                radius: 1.5
                color: Qt.alpha(root.levelColor, 0.85)
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.pct) + "%"
            color: root.levelColor
            font { family: Theme.font; pixelSize: Theme.barText; weight: Font.Bold }
        }
    }

    popup: Component {
        ColumnLayout {
            spacing: 12
            implicitHeight: childrenRect.height

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: Math.round(root.pct) + "%"
                    color: root.levelColor
                    font { family: Theme.font; pixelSize: 28; weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.dev.state === UPowerDeviceState.FullyCharged ? "Completa"
                        : root.charging ? "Cargando"
                        : root.plugged ? "Conectada (sin cargar)"
                        : "Descargando"
                    color: Theme.subtext0
                    font { family: Theme.font; pixelSize: 12 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Theme.surface0
                Rectangle {
                    width: parent.width * Math.min(1, root.pct / 100)
                    height: parent.height
                    radius: 3
                    color: root.levelColor
                }
            }

            Repeater {
                model: [
                    { k: "Consumo", v: root.dev.changeRate > 0 ? root.dev.changeRate.toFixed(1) + " W" : "—" },
                    { k: root.charging ? "Para llenar" : "Tiempo restante",
                      v: root.fmtTime(root.charging ? root.dev.timeToFull : root.dev.timeToEmpty) },
                    { k: "Energía", v: root.dev.energy.toFixed(1) + " / " + root.dev.energyCapacity.toFixed(1) + " Wh" },
                    { k: "Salud", v: root.dev.healthSupported ? Math.round(root.dev.healthPercentage) + "%" : "—" }
                ]
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: modelData.k
                        color: Theme.subtext0
                        font { family: Theme.font; pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: modelData.v
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
            }

            Text {
                text: "Perfil de rendimiento"
                color: Theme.subtext0
                font { family: Theme.font; pixelSize: 11 }
                Layout.topMargin: 4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [
                        { name: "Ahorro", icon: "󰌪", p: PowerProfile.PowerSaver, c: Theme.ok },
                        { name: "Balance", icon: "󰾅", p: PowerProfile.Balanced, c: Theme.mauve },
                        { name: "Máximo", icon: "󱐋", p: PowerProfile.Performance, c: Theme.peach }
                    ]
                    Rectangle {
                        id: btn
                        readonly property bool active: PowerProfiles.profile === modelData.p
                        readonly property bool disabled: modelData.p === PowerProfile.Performance
                            && !PowerProfiles.hasPerformanceProfile
                        Layout.fillWidth: true
                        height: 56
                        radius: 10
                        opacity: disabled ? 0.4 : 1
                        color: active ? modelData.c
                             : ma.containsMouse ? Theme.surface1 : Theme.surface0

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: btn.active ? Theme.crust : modelData.c
                                font { family: Theme.font; pixelSize: 18 }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name
                                color: btn.active ? Theme.crust : Theme.text
                                font { family: Theme.font; pixelSize: 11; weight: Font.Bold }
                            }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !btn.disabled
                            onClicked: PowerProfiles.profile = modelData.p
                        }
                    }
                }
            }
        }
    }
}
