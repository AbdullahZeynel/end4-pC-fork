import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: timersTab
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property var presets: [1, 5, 10, 25]

    function formatRemaining(seconds) {
        const s = Math.max(0, seconds);
        const hours = Math.floor(s / 3600);
        const minutes = Math.floor((s % 3600) / 60);
        const secs = s % 60;
        if (hours > 0)
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 6
        }
        spacing: 8

        Rectangle {
            id: ringingBanner
            readonly property var current: AlarmService.ringing.find(r => r.kind === "countdown") ?? null
            visible: current !== null
            Layout.fillWidth: true
            implicitHeight: ringingRow.implicitHeight + 16
            radius: Appearance.rounding.small
            color: Appearance.colors.colErrorContainer

            RowLayout {
                id: ringingRow
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 8
                    bottomMargin: 8
                }
                spacing: 8

                MaterialSymbol {
                    text: "timer"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnErrorContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnErrorContainer
                    text: {
                        const label = ringingBanner.current?.label ?? "";
                        return label.length > 0 ? label : Translation.tr("Time's up");
                    }
                }

                RippleButton {
                    implicitHeight: 30
                    implicitWidth: 70
                    onClicked: AlarmService.dismiss("countdown", ringingBanner.current.id)
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Dismiss")
                        color: Appearance.colors.colOnPrimary
                    }
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                }
            }
        }

        StyledListView {
            id: timerList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            clip: true
            popin: true
            model: AlarmService.countdowns

            delegate: Rectangle {
                id: timerItem
                required property var modelData
                width: timerList.width
                implicitHeight: timerRow.implicitHeight + 16
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2

                RowLayout {
                    id: timerRow
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 6
                        topMargin: 8
                        bottomMargin: 8
                    }
                    spacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            font.pixelSize: 26
                            font.features: {
                                "tnum": 1
                            }
                            color: Appearance.m3colors.m3onSurface
                            // Depends on AlarmService.now, so it reticks every second.
                            text: timersTab.formatRemaining(AlarmService.countdownRemaining(timerItem.modelData))
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: {
                                const parts = [];
                                if (timerItem.modelData.label.length > 0)
                                    parts.push(timerItem.modelData.label);
                                parts.push(Translation.tr("%1 min").arg(Math.round(timerItem.modelData.duration / 60)));
                                return parts.join(" · ");
                            }
                        }
                    }

                    RippleButton {
                        implicitHeight: 32
                        implicitWidth: 32
                        buttonRadius: Appearance.rounding.full
                        onClicked: AlarmService.toggleCountdown(timerItem.modelData.id)
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            text: timerItem.modelData.running ? "pause" : "play_arrow"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer2
                        }
                    }

                    RippleButton {
                        implicitHeight: 32
                        implicitWidth: 32
                        buttonRadius: Appearance.rounding.full
                        onClicked: AlarmService.resetCountdown(timerItem.modelData.id)
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            text: "refresh"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer2
                        }
                    }

                    RippleButton {
                        implicitHeight: 32
                        implicitWidth: 32
                        buttonRadius: Appearance.rounding.full
                        onClicked: AlarmService.removeCountdown(timerItem.modelData.id)
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            text: "delete"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer2
                        }
                    }
                }
            }
        }

        // New timer
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: timersTab.presets
                delegate: RippleButton {
                    id: presetButton
                    required property var modelData
                    implicitHeight: 32
                    Layout.fillWidth: true
                    onClicked: AlarmService.startCountdown(AlarmService.addCountdown(presetButton.modelData * 60, ""))
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("%1m").arg(presetButton.modelData)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }

            StyledSpinBox {
                id: customMinutes
                from: 1
                to: 600
                value: 15
            }

            RippleButton {
                implicitHeight: 35
                implicitWidth: 80
                onClicked: AlarmService.startCountdown(AlarmService.addCountdown(customMinutes.value * 60, ""))
                contentItem: StyledText {
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Start")
                    color: Appearance.colors.colOnPrimary
                }
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
            }
        }
    }
}
