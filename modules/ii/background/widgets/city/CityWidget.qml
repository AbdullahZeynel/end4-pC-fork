pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

/**
 * One city: its local time, its current weather, and a photo of it.
 *
 * Replaces running the four-timezone World Clock and the Weather widget side
 * by side when you only ever care about one place. The photo is referenced by
 * path and never bundled with the repo, so no image licensing rides along.
 */
AbstractBackgroundWidget {
    id: root

    configEntryName: "city"

    readonly property var cfg: Config.options.background.widgets.city
    readonly property bool hasPhoto: photo.status === Image.Ready

    property string nowTime: ""
    property string nowDate: ""

    implicitWidth: 320
    implicitHeight: 208

    function refresh() {
        const now = new Date();
        const tz = root.cfg.timezone;
        root.nowTime = now.toLocaleTimeString("en-GB", {
            timeZone: tz, hour: "2-digit", minute: "2-digit"
        });
        root.nowDate = now.toLocaleDateString("en-GB", {
            timeZone: tz, weekday: "long", day: "numeric", month: "long"
        });
    }

    function weatherIcon() {
        const desc = (Weather.data?.description ?? "").toLowerCase();
        if (desc.includes("thunder")) return "thunderstorm";
        if (desc.includes("rain") || desc.includes("drizzle")) return "rainy";
        if (desc.includes("snow")) return "weather_snowy";
        if (desc.includes("clear")) return "clear_day";
        if (desc.includes("cloud") || desc.includes("overcast")) return "cloud";
        if (desc.includes("fog") || desc.includes("mist")) return "foggy";
        return "thermostat";
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    StyledDropShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding?.verylarge ?? 30
        color: Appearance.colors.colWidgetPanel

        Image {
            id: photo
            anchors.fill: parent
            source: root.cfg.imagePath !== "" ? "file://" + root.cfg.imagePath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false // drawn through the rounded mask below
        }

        OpacityMask {
            anchors.fill: parent
            source: photo
            visible: root.hasPhoto
            opacity: root.cfg.imageOpacity
            maskSource: Rectangle {
                width: card.width
                height: card.height
                radius: card.radius
            }
        }

        // Keeps the text legible over whatever the photo happens to be.
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            visible: root.hasPhoto
            opacity: 0.55
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Appearance.colors.colScrim }
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 18
            }
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: "location_on"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.cfg.cityLabel
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnPrimaryContainer
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillHeight: true }

            StyledText {
                Layout.fillWidth: true
                text: root.nowTime
                font.pixelSize: 64
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnPrimaryContainer
            }

            StyledText {
                Layout.fillWidth: true
                text: root.nowDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnPrimaryContainer
                opacity: 0.75
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8

                MaterialSymbol {
                    text: root.weatherIcon()
                    iconSize: Appearance.font.pixelSize.huge
                    fill: 1
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    text: (Weather.data?.temp ?? "--")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnPrimaryContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Weather.data?.description ?? Translation.tr("No weather data")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.75
                    elide: Text.ElideRight
                }
            }
        }
    }
}
