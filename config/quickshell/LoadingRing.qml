// Anillo de carga: arco que gira sobre una pista tenue. Lo comparten el greeter
// (config/greeter) y el splash de arranque de la sesión (Splash.qml).
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color color: Theme.mauve
    property color track: Theme.surface0
    property real lineWidth: 4
    property bool running: true

    implicitWidth: 72
    implicitHeight: 72

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.track
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2; radiusY: radiusX
                startAngle: 0; sweepAngle: 360
            }
        }
    }

    Shape {
        id: arc
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: (root.width - root.lineWidth) / 2; radiusY: radiusX
                startAngle: -90; sweepAngle: 100
            }
        }

        RotationAnimator on rotation {
            from: 0; to: 360
            duration: 1100
            loops: Animation.Infinite
            running: root.running
        }
    }
}
