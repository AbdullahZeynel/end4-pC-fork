pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common

/**
 * Frosted-glass backdrop for desktop widgets.
 *
 * Samples the region of the wallpaper that sits directly behind the widget,
 * blurs and tints it, then draws a glowing neon edge on top. Positioning the
 * sampled image by the widget's own x/y is what sells the effect: the blur
 * lines up with what's actually behind the widget instead of being a generic
 * smear, so it tracks correctly while the widget is dragged around.
 *
 * Loaded only when Config.options.appearance.glass.enable is true.
 */
Item {
    id: root

    property string wallpaperPath: ""
    property real screenW: 0
    property real screenH: 0
    property real widgetX: 0
    property real widgetY: 0
    property real cornerRadius: Appearance.rounding?.verylarge ?? 30

    readonly property var cfg: Config.options.appearance.glass
    readonly property color neonColor: Appearance.colors.colNeon

    Item {
        id: wallpaperSample
        anchors.fill: parent
        visible: false // sampled by FastBlur, never drawn directly
        clip: true

        Image {
            source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
            width: root.screenW
            height: root.screenH
            x: -root.widgetX
            y: -root.widgetY
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }

    FastBlur {
        anchors.fill: parent
        source: wallpaperSample
        radius: root.cfg.blurRadius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: root.width
                height: root.height
                radius: root.cornerRadius
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Appearance.colors.colScrim
        opacity: root.cfg.tintOpacity
    }

    Loader {
        anchors.fill: parent
        active: root.cfg.neonEnable

        sourceComponent: Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: "transparent"
            border.width: root.cfg.neonWidth
            border.color: Qt.rgba(root.neonColor.r, root.neonColor.g, root.neonColor.b, root.cfg.neonOpacity)

            layer.enabled: root.cfg.neonGlow > 0
            layer.effect: Glow {
                radius: root.cfg.neonGlow
                samples: Math.min(33, Math.round(root.cfg.neonGlow) * 2 + 1)
                color: root.neonColor
                spread: 0.3
            }
        }
    }
}
