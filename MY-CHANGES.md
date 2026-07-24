# My changes

Everything in this file is what **I** changed relative to
[pctrade/end4-pC](https://github.com/pctrade/end4-pC). Everything *not* listed here is upstream's
work — see the [credits](README.md#-credits).

This file exists partly to be a courtesy to anyone reading the fork, and partly because GPL-3.0 §5(a)
asks modified versions to carry prominent notices saying that they were changed and when.

The authoritative record is always the git history: `git diff main..mine`.

---

## 2026-07-24 — Fork setup

- **Rebranded README** for this fork, with the full attribution chain
  (end-4 → pctrade → me) stated up front. Upstream's showcase video was removed since it
  showcases pctrade's rice, not mine. All existing credits kept.
- **`modules/ii/settings/pages/About.qml`** — made the in-app "update" button non-destructive.
  It previously ran `rm -rf end4-pC && git clone …`, which wipes local changes, branches and
  the entire git history on every update. It now does a `git pull --ff-only` in place, and
  restarts the shell even if the pull fails so a dirty tree can't leave you without a desktop.
- **`scripts/presets.sh`** — resolve the script directory from `BASH_SOURCE` instead of
  hardcoding `~/.config/quickshell/end4-pC/scripts`. Works regardless of what the config
  folder is named. *(Candidate for an upstream PR — it's a fix, not a preference.)*
- Added this file and a `.gitignore`.

### Image Converter — file picker

- **`modules/ii/background/widgets/images/ImageConverterWidget.qml`** — added a
  "Choose files…" button that opens `kdialog`, so images can be selected without
  drag-and-drop. Dragging still works unchanged; both paths feed the same
  `enqueueFiles()`. Multi-select supported via `--multiple --separate-output`.
  Follows the picker already used in `modules/ii/sidebarRight/SidebarRightContent.qml`.
  Widget height 252 → 300px to fit the button.
  *(Upstream PR candidate — branch `feat/image-converter-file-picker`.)*

### Frosted glass + neon widget styling

- **`modules/ii/background/widgets/GlassBackground.qml`** (new) — samples the wallpaper
  region behind a widget, blurs and tints it, and draws a glowing neon edge. The sample is
  offset by the widget's own x/y, so the blur matches what is actually behind it and tracks
  while the widget is dragged.
- **`AbstractBackgroundWidget.qml`** — loads the backdrop behind widget content through a
  `Loader`, so nothing is built when the feature is off. Widgets that draw no panel of their
  own (clock, visualizer) opt out via `useGlass: false`.
- **`Appearance.qml`** — added `colWidgetPanel` and `colNeon`. `colWidgetPanel` is byte-identical
  to `colPrimaryContainer` unless glass is on, so no other surface in the shell is touched.
- **`Config.qml`** — new `appearance.glass` block: `enable` (default **false**), `panelTransparency`,
  `blurRadius`, `tintOpacity`, `neonEnable`, `neonWidth`, `neonGlow`, `neonOpacity`, `neonLightness`.
- Six widgets swapped their panel fill to `colWidgetPanel` (one line each): calendar, image
  converter, media, resources, weather, world clock.
  *(Upstream PR candidate — branch `feat/glass-widget-style`.)*

### City widget

- **`modules/ii/background/widgets/city/CityWidget.qml`** (new) — one city's local time,
  current weather and a photo of it, in place of running the four-timezone World Clock and
  the Weather widget side by side. Registered in `Config.qml`, `Background.qml` and
  `WidgetsSubmenu.qml`. `imagePath` defaults to empty and the photo is referenced by path,
  so **no image is ever committed** and no image licensing rides along with the fork.
  Defaults to Ankara / `Europe/Istanbul`, both configurable.

### Downloader (yt-dlp) widget

- **`modules/ii/background/widgets/ytdlp/YtDlpWidget.qml`** (new) — paste a URL, the title is
  fetched via `yt-dlp --print` and pre-filled but stays editable (typing in the name field
  stops it being overwritten), choose a container, download. Audio formats go through
  `-x --audio-format`, video through `-f "bv*+ba/b" --merge-output-format`. Output directory
  configurable, defaults to `~/Downloads`. Registered in `Config.qml`, `Background.qml`
  (module import included) and `WidgetsSubmenu.qml`.

### Alarms and countdown timers

- **`services/AlarmService.qml`** (new) — alarms and countdown timers. Deliberately separate
  from upstream's `TimerService.qml`, which already covers pomodoro and stopwatch: those measure
  an interval you are watching, these fire at a wall-clock moment you may not be.
- **`shell.qml`** — calls `AlarmService.load()` at startup. QML singletons are only created on
  first use, so without this the service would only tick while something happened to be looking
  at it, and an alarm would not fire with every panel closed. Same `function load() {}` idiom
  upstream already uses for `Wallpapers` and `Updates`.
- **State** lives in its own `alarms.json` (`Directories.alarmsPath`) rather than
  `Persistent.qml`'s `states.json`, following the `Todo.qml` pattern — a list of objects
  round-trips safely through a plain `FileView`, and these are user data, not shell state.
- **Catch-up on restart** — due times are stored absolute, so one code path handles the shell
  having been closed, the machine asleep, or a normal tick. Anything that came due more than
  `missedGraceMinutes` ago is marked *missed* and rescheduled rather than ringing hours late.
- **`IpcHandler`** with `silence`, `snoozeAll` and `status`, so a ringing alarm can always be
  stopped from a terminal or a keybind and never only from the sidebar:
  `qs -c end4-pC-fork ipc call alarms silence`. Worth binding to a key.
- **`Config.qml`** — new `time.alarms` block (`snoozeMinutes`, `missedGraceMinutes`,
  `ringTimeoutSeconds`, `soundRepeatSeconds`, `sound`) and `sounds.alarm`.
- **UI** — `Alarms.qml` and `Timers.qml` added as two more tabs in the existing
  `sidebarRight/pomodoro/` module, so Pomodoro / Stopwatch / Alarms / Timers now share one
  tab bar. Ringing shows an in-tab banner with Snooze and Dismiss; Escape silences.

---

## Gotchas learned the hard way

- **Never check out a `main`-based branch while `qs` is running.**
  `~/.config/quickshell/end4-pC-fork` is a symlink to this repo, so the checked-out branch is
  what the shell loads. Checking out a `feat/*` branch off `main` makes quickshell hot-reload
  upstream's `Config.qml`, whose JsonAdapter then **rewrites
  `~/.config/illogical-impulse/config.json` with every key it doesn't recognise deleted** — this
  wiped the whole `appearance.glass` block, disabled two widgets and repositioned the rest.
  Git history is untouched, which makes it look like lost code when it isn't.
  Build on `mine` and cherry-pick onto a clean `feat/*` branch at the end instead.
- **A key missing from `config.json` does not mean the feature is broken.** quickshell only
  writes the file when a value changes, so a newly added `Config.qml` block simply never appears
  until something touches it — the defaults are held in memory. `city` and `ytdlp` were absent
  from the file for this reason. To enable one: `killall qs`, add the block with `jq`, restart.

---

## Upstream bugs spotted (not yet reported)

- `modules/ii/sidebarRight/SidebarRightContent.qml` lines 41/46/47 call
  `filterDuplicatePlayers()`, which is only defined in `modules/ii/mediaControls/MediaControls.qml`.
  Spams `ReferenceError: filterDuplicatePlayers is not defined` on every media update.
  Untouched by this fork — worth an upstream issue or PR.

---

## Planned

In rough priority order. Deliberately kept as a queue rather than worked in parallel —
the clock service alone was a session's worth of work.

- [ ] **Clock face redesign** — make it cooler. Check `Config.options.background.widgets.clock`
      first: there are existing `style`, `cookie.*` and `digital.*` options, so some of this
      may be configuration rather than new code.
- [ ] **Calendar: tasks on days** — the To Do service and per-day calendar cells already exist.
      Needs todo items to carry an optional date, markers on days that have one, and a
      click-through from a day to its tasks. Data model change first, UI second.
- [ ] **Smart widget auto-placement** — the existing `placementStrategy: "leastBusy"` positions
      each widget independently with no knowledge of the others, so they overlap. Wanted: a
      collision-aware pass on wallpaper change that aligns widgets to a shared grid with
      consistent gutters, writes the result into each widget's stored x/y, and hands control
      back so they stay draggable. `AbstractWidget` already has `gridSize: 12`, `snapEnabled`,
      `snap()`, and the canvas draws alignment guides — build on those.
- [ ] **Click-to-pin the bar popup** — it opens on hover and vanishes on hover-out; a click
      should pin it so it can be interacted with.
- [ ] **Redesign the Downloader widget** (`widgets/ytdlp/YtDlpWidget.qml`) — it works but reads
      as a plain stack of form fields.

### Also outstanding

- [ ] Push `feat/image-converter-file-picker` and open a PR against `pctrade/end4-pC` — clean
      single-feature diff, ready to go.
- [ ] Report the `filterDuplicatePlayers()` upstream bug recorded above.
- [ ] Consider splitting the alarms/timers work onto a `feat/alarms-timers` branch for an
      upstream PR — it touches only one upstream file meaningfully (`PomodoroWidget.qml`).
