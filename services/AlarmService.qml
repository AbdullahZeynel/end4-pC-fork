pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Alarms and countdown timers.
 *
 * Deliberately separate from TimerService (pomodoro + stopwatch): those measure
 * an interval you are watching, these fire at a wall-clock moment you may not be.
 *
 * The service must tick even when no panel is open, and QML singletons are only
 * instantiated on first use, so shell.qml calls load() at startup to force it
 * into existence. Without that an alarm would only run while something happened
 * to be looking at it.
 *
 * State lives in its own file rather than Persistent.qml's states.json. Alarms are
 * a list of objects, which is the shape Todo.qml already round-trips safely through
 * a plain FileView, and they are user data rather than ephemeral shell state.
 *
 * Alarm:   { id, label, hour, minute, days, enabled, nextAt, snoozedUntil, missedAt }
 *          days is an array of JS weekdays (0 = Sunday); empty means fire once.
 *          nextAt / snoozedUntil / missedAt are epoch seconds, 0 when unset.
 * Countdown: { id, label, duration, endsAt, remaining, running }
 *          duration/remaining are seconds, endsAt is epoch seconds (0 when not running).
 */
Singleton {
    id: root

    property var alarms: []
    property var countdowns: []

    // Whatever is going off right now: [{ kind: "alarm"|"countdown", id, label, at }]
    property var ringing: []

    // Bumped every tick so time-dependent bindings in the UI re-evaluate.
    property int now: Math.floor(Date.now() / 1000)

    readonly property int snoozeSeconds: (Config.options.time.alarms.snoozeMinutes ?? 5) * 60
    readonly property int graceSeconds: (Config.options.time.alarms.missedGraceMinutes ?? 5) * 60
    readonly property int ringTimeout: Config.options.time.alarms.ringTimeoutSeconds ?? 300

    function load() {} // For forcing initialization

    // ---------------------------------------------------------------- helpers

    function currentSeconds() {
        return Math.floor(Date.now() / 1000);
    }

    function newId(prefix) {
        return `${prefix}${Date.now()}${Math.floor(Math.random() * 1000)}`;
    }

    /**
     * First occurrence of hour:minute strictly after `after` (epoch seconds).
     * `days` empty means "the next time that clock time comes round".
     */
    function computeNextAt(hour, minute, days, after) {
        const from = new Date(after * 1000);
        for (let offset = 0; offset <= 8; offset++) {
            const candidate = new Date(from.getFullYear(), from.getMonth(), from.getDate() + offset, hour, minute, 0, 0);
            const candidateSec = Math.floor(candidate.getTime() / 1000);
            if (candidateSec <= after)
                continue;
            if (days.length > 0 && days.indexOf(candidate.getDay()) === -1)
                continue;
            return candidateSec;
        }
        return 0;
    }

    function alarmIndex(id) {
        return root.alarms.findIndex(a => a.id === id);
    }

    function countdownIndex(id) {
        return root.countdowns.findIndex(c => c.id === id);
    }

    // ------------------------------------------------------------------ alarms

    function addAlarm(hour, minute, days, label) {
        const alarm = {
            "id": newId("a"),
            "label": label ?? "",
            "hour": hour,
            "minute": minute,
            "days": days ?? [],
            "enabled": true,
            "nextAt": computeNextAt(hour, minute, days ?? [], currentSeconds()),
            "snoozedUntil": 0,
            "missedAt": 0
        };
        root.alarms = root.alarms.concat([alarm]);
        save();
        return alarm.id;
    }

    /**
     * Patch an alarm in place. Any change to the schedule reschedules it, and
     * clears a stale "missed" marker so the UI doesn't keep showing it.
     */
    function updateAlarm(id, patch) {
        const index = alarmIndex(id);
        if (index === -1)
            return;
        const updated = Object.assign({}, root.alarms[index], patch);
        const rescheduled = patch.hour !== undefined || patch.minute !== undefined || patch.days !== undefined || patch.enabled !== undefined;
        if (rescheduled) {
            updated.snoozedUntil = 0;
            updated.missedAt = 0;
            updated.nextAt = updated.enabled ? computeNextAt(updated.hour, updated.minute, updated.days, currentSeconds()) : 0;
            dismiss("alarm", id);
        }
        const copy = root.alarms.slice(0);
        copy[index] = updated;
        root.alarms = copy;
        save();
    }

    function setAlarmEnabled(id, enabled) {
        updateAlarm(id, {
            "enabled": enabled
        });
    }

    function toggleAlarm(id) {
        const index = alarmIndex(id);
        if (index === -1)
            return;
        setAlarmEnabled(id, !root.alarms[index].enabled);
    }

    function removeAlarm(id) {
        dismiss("alarm", id);
        root.alarms = root.alarms.filter(a => a.id !== id);
        save();
    }

    // -------------------------------------------------------------- countdowns

    function addCountdown(seconds, label) {
        const countdown = {
            "id": newId("c"),
            "label": label ?? "",
            "duration": seconds,
            "endsAt": 0,
            "remaining": seconds,
            "running": false
        };
        root.countdowns = root.countdowns.concat([countdown]);
        save();
        return countdown.id;
    }

    function patchCountdown(id, patch) {
        const index = countdownIndex(id);
        if (index === -1)
            return;
        const copy = root.countdowns.slice(0);
        copy[index] = Object.assign({}, copy[index], patch);
        root.countdowns = copy;
        save();
    }

    function startCountdown(id) {
        const index = countdownIndex(id);
        if (index === -1)
            return;
        const countdown = root.countdowns[index];
        const remaining = countdown.remaining > 0 ? countdown.remaining : countdown.duration;
        dismiss("countdown", id);
        patchCountdown(id, {
            "running": true,
            "remaining": remaining,
            "endsAt": currentSeconds() + remaining
        });
    }

    function pauseCountdown(id) {
        const index = countdownIndex(id);
        if (index === -1)
            return;
        const countdown = root.countdowns[index];
        patchCountdown(id, {
            "running": false,
            "remaining": Math.max(0, countdown.endsAt - currentSeconds()),
            "endsAt": 0
        });
    }

    function toggleCountdown(id) {
        const index = countdownIndex(id);
        if (index === -1)
            return;
        if (root.countdowns[index].running)
            pauseCountdown(id);
        else
            startCountdown(id);
    }

    function resetCountdown(id) {
        const index = countdownIndex(id);
        if (index === -1)
            return;
        dismiss("countdown", id);
        patchCountdown(id, {
            "running": false,
            "endsAt": 0,
            "remaining": root.countdowns[index].duration
        });
    }

    function removeCountdown(id) {
        dismiss("countdown", id);
        root.countdowns = root.countdowns.filter(c => c.id !== id);
        save();
    }

    /** Seconds left, whether running or paused. */
    function countdownRemaining(countdown) {
        if (!countdown.running)
            return countdown.remaining;
        return Math.max(0, countdown.endsAt - root.now);
    }

    // ----------------------------------------------------------------- ringing

    function isRinging(kind, id) {
        return root.ringing.some(r => r.kind === kind && r.id === id);
    }

    function ring(kind, id, label, title) {
        if (isRinging(kind, id))
            return;
        root.ringing = root.ringing.concat([
            {
                "kind": kind,
                "id": id,
                "label": label,
                "at": currentSeconds()
            }
        ]);

        // Critical urgency so the notification doesn't quietly time out while
        // the alarm is still going.
        Quickshell.execDetached(["notify-send", title, label && label.length > 0 ? label : Translation.tr("Time's up"), "-a", "Shell", "-u", "critical"]);
        playRingSound();
    }

    function playRingSound() {
        if (!Config.options.sounds.alarm)
            return;
        Audio.playSystemSound(Config.options.time.alarms.sound ?? "alarm-clock-elapsed");
    }

    function dismiss(kind, id) {
        root.ringing = root.ringing.filter(r => !(r.kind === kind && r.id === id));
    }

    function dismissAll() {
        root.ringing = [];
    }

    /** Silence it now, bring it back in snoozeMinutes. Alarms only. */
    function snooze(id) {
        const index = alarmIndex(id);
        if (index === -1)
            return;
        dismiss("alarm", id);
        const copy = root.alarms.slice(0);
        copy[index] = Object.assign({}, copy[index], {
            "snoozedUntil": currentSeconds() + root.snoozeSeconds
        });
        root.alarms = copy;
        save();
    }

    // -------------------------------------------------------------------- tick

    /**
     * One pass over everything scheduled. Written to be correct when called after
     * an arbitrary gap (shell restarted, machine suspended) rather than assuming
     * it runs every second: due times are absolute, and anything more than
     * graceSeconds late is recorded as missed instead of going off hours later.
     */
    function tick() {
        const nowSec = currentSeconds();
        root.now = nowSec;

        let alarmsChanged = false;
        const nextAlarms = root.alarms.map(alarm => {
            if (!alarm.enabled)
                return alarm;

            // A snoozed alarm is waiting on its snooze, not on its schedule.
            if (alarm.snoozedUntil > 0) {
                if (nowSec >= alarm.snoozedUntil) {
                    alarmsChanged = true;
                    ring("alarm", alarm.id, alarm.label, Translation.tr("Alarm"));
                    return Object.assign({}, alarm, {
                        "snoozedUntil": 0
                    });
                }
                return alarm;
            }

            if (alarm.nextAt <= 0 || nowSec < alarm.nextAt)
                return alarm;

            const dueAt = alarm.nextAt;
            const lateBy = nowSec - dueAt;
            alarmsChanged = true;

            // Advance the schedule first, so a failure to ring can't wedge it.
            const patch = alarm.days.length > 0 ? {
                "nextAt": computeNextAt(alarm.hour, alarm.minute, alarm.days, nowSec)
            } : {
                "nextAt": 0,
                "enabled": false
            };

            if (lateBy <= root.graceSeconds) {
                ring("alarm", alarm.id, alarm.label, Translation.tr("Alarm"));
                patch.missedAt = 0;
            } else {
                patch.missedAt = dueAt;
            }
            return Object.assign({}, alarm, patch);
        });

        let countdownsChanged = false;
        const nextCountdowns = root.countdowns.map(countdown => {
            if (!countdown.running || countdown.endsAt <= 0 || nowSec < countdown.endsAt)
                return countdown;

            countdownsChanged = true;
            const lateBy = nowSec - countdown.endsAt;
            if (lateBy <= root.graceSeconds)
                ring("countdown", countdown.id, countdown.label, Translation.tr("Timer"));
            return Object.assign({}, countdown, {
                "running": false,
                "endsAt": 0,
                "remaining": 0
            });
        });

        if (alarmsChanged)
            root.alarms = nextAlarms;
        if (countdownsChanged)
            root.countdowns = nextCountdowns;
        if (alarmsChanged || countdownsChanged)
            save();

        // Stop nagging eventually if nobody is around to dismiss it.
        if (root.ringing.length > 0 && root.ringTimeout > 0) {
            const stillRinging = root.ringing.filter(r => nowSec - r.at < root.ringTimeout);
            if (stillRinging.length !== root.ringing.length)
                root.ringing = stillRinging;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    Timer {
        interval: Math.max(1, Config.options.time.alarms.soundRepeatSeconds ?? 5) * 1000
        running: root.ringing.length > 0
        repeat: true
        onTriggered: root.playRingSound()
    }

    /**
     * An escape hatch that does not depend on the sidebar being open, or on the
     * shell's UI working at all:
     *   qs -c end4-pC-fork ipc call alarms silence
     * Worth binding to a key. Without this, a ringing alarm can only be stopped
     * by killing the shell.
     */
    IpcHandler {
        target: "alarms"

        function silence(): void {
            root.dismissAll();
        }

        function snoozeAll(): void {
            root.ringing.filter(r => r.kind === "alarm").forEach(r => root.snooze(r.id));
            root.dismissAll();
        }

        function status(): string {
            if (root.ringing.length === 0)
                return "nothing ringing";
            return root.ringing.map(r => `${r.kind}: ${r.label || "(no label)"}`).join("\n");
        }
    }

    // ------------------------------------------------------------- persistence

    function save() {
        alarmsFileView.setText(JSON.stringify({
            "alarms": root.alarms,
            "countdowns": root.countdowns
        }));
    }

    function refresh() {
        alarmsFileView.reload();
    }

    Component.onCompleted: refresh()

    FileView {
        id: alarmsFileView
        path: Qt.resolvedUrl(Directories.alarmsPath)

        onLoaded: {
            try {
                const data = JSON.parse(alarmsFileView.text());
                root.alarms = data.alarms ?? [];
                root.countdowns = data.countdowns ?? [];
            } catch (e) {
                console.log("[Alarms] Could not parse file, starting empty:", e);
                root.alarms = [];
                root.countdowns = [];
            }
            // Catch up on anything that came due while the shell was down.
            root.tick();
            console.log(`[Alarms] Loaded ${root.alarms.length} alarm(s), ${root.countdowns.length} timer(s)`);
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                console.log("[Alarms] File not found, creating new file.");
                root.alarms = [];
                root.countdowns = [];
                root.save();
            } else {
                console.log("[Alarms] Error loading file: " + error);
            }
        }
    }
}
