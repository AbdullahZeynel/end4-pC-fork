import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: alarmsTab
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Monday-first for display; the stored values are JS weekdays (0 = Sunday).
    readonly property var dayOrder: [1, 2, 3, 4, 5, 6, 0]
    readonly property var dayLabels: ({
            0: Translation.tr("S"),
            1: Translation.tr("M"),
            2: Translation.tr("T"),
            3: Translation.tr("W"),
            4: Translation.tr("T"),
            5: Translation.tr("F"),
            6: Translation.tr("S")
        })

    property var draftDays: []

    function twoDigit(n) {
        return n.toString().padStart(2, '0');
    }

    function repeatSummary(alarm) {
        if (alarm.days.length === 0)
            return Translation.tr("Once");
        if (alarm.days.length === 7)
            return Translation.tr("Every day");
        return alarmsTab.dayOrder.filter(d => alarm.days.indexOf(d) !== -1).map(d => alarmsTab.dayLabels[d]).join(" ");
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

        // Whatever is going off right now, with the only two useful actions.
        Rectangle {
            id: ringingBanner
            readonly property var current: AlarmService.ringing.find(r => r.kind === "alarm") ?? null
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
                    text: "alarm_on"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnErrorContainer
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnErrorContainer
                    text: {
                        const label = ringingBanner.current?.label ?? "";
                        return label.length > 0 ? label : Translation.tr("Alarm");
                    }
                }

                RippleButton {
                    implicitHeight: 30
                    implicitWidth: 70
                    onClicked: AlarmService.snooze(ringingBanner.current.id)
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Snooze")
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                }

                RippleButton {
                    implicitHeight: 30
                    implicitWidth: 70
                    onClicked: AlarmService.dismiss("alarm", ringingBanner.current.id)
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
            id: alarmList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            clip: true
            popin: true
            model: AlarmService.alarms

            delegate: Rectangle {
                id: alarmItem
                required property var modelData
                width: alarmList.width
                implicitHeight: alarmRow.implicitHeight + 16
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2

                RowLayout {
                    id: alarmRow
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 6
                        topMargin: 8
                        bottomMargin: 8
                    }
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            font.pixelSize: 26
                            font.features: {
                                "tnum": 1
                            }
                            opacity: alarmItem.modelData.enabled ? 1 : 0.45
                            color: Appearance.m3colors.m3onSurface
                            text: `${alarmsTab.twoDigit(alarmItem.modelData.hour)}:${alarmsTab.twoDigit(alarmItem.modelData.minute)}`
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            opacity: alarmItem.modelData.enabled ? 1 : 0.45
                            color: alarmItem.modelData.missedAt > 0 ? Appearance.colors.colError : Appearance.colors.colSubtext
                            text: {
                                const parts = [alarmsTab.repeatSummary(alarmItem.modelData)];
                                if (alarmItem.modelData.label.length > 0)
                                    parts.push(alarmItem.modelData.label);
                                if (alarmItem.modelData.snoozedUntil > 0)
                                    parts.push(Translation.tr("snoozed"));
                                if (alarmItem.modelData.missedAt > 0)
                                    parts.push(Translation.tr("missed"));
                                return parts.join(" · ");
                            }
                        }
                    }

                    StyledSwitch {
                        checked: alarmItem.modelData.enabled
                        onToggled: AlarmService.setAlarmEnabled(alarmItem.modelData.id, checked)
                    }

                    RippleButton {
                        implicitHeight: 32
                        implicitWidth: 32
                        buttonRadius: Appearance.rounding.full
                        onClicked: AlarmService.removeAlarm(alarmItem.modelData.id)
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

        // New alarm
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledSpinBox {
                    id: hourBox
                    from: 0
                    to: 23
                    value: 7
                }

                StyledText {
                    text: ":"
                    color: Appearance.colors.colSubtext
                }

                StyledSpinBox {
                    id: minuteBox
                    from: 0
                    to: 59
                    value: 0
                }

                Item {
                    Layout.fillWidth: true
                }

                RippleButton {
                    implicitHeight: 35
                    implicitWidth: 80
                    onClicked: {
                        AlarmService.addAlarm(hourBox.value, minuteBox.value, alarmsTab.draftDays.slice(0), labelField.text);
                        labelField.text = "";
                        alarmsTab.draftDays = [];
                    }
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("Add")
                        color: Appearance.colors.colOnPrimary
                    }
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: alarmsTab.dayOrder
                    delegate: RippleButton {
                        id: dayButton
                        required property var modelData
                        readonly property bool picked: alarmsTab.draftDays.indexOf(modelData) !== -1
                        implicitHeight: 28
                        implicitWidth: 28
                        buttonRadius: Appearance.rounding.full
                        onClicked: {
                            if (picked)
                                alarmsTab.draftDays = alarmsTab.draftDays.filter(d => d !== modelData);
                            else
                                alarmsTab.draftDays = alarmsTab.draftDays.concat([modelData]);
                        }
                        colBackground: picked ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        colBackgroundHover: picked ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer2Hover
                        contentItem: StyledText {
                            horizontalAlignment: Text.AlignHCenter
                            text: alarmsTab.dayLabels[dayButton.modelData]
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: dayButton.picked ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2

                    StyledTextInput {
                        id: labelField
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer2
                        onAccepted: {
                            AlarmService.addAlarm(hourBox.value, minuteBox.value, alarmsTab.draftDays.slice(0), text);
                            text = "";
                            alarmsTab.draftDays = [];
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: labelField.text.length === 0
                            text: Translation.tr("Label")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
