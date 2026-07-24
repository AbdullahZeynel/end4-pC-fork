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

---

## Upstream bugs spotted (not yet reported)

- `modules/ii/sidebarRight/SidebarRightContent.qml` lines 41/46/47 call
  `filterDuplicatePlayers()`, which is only defined in `modules/ii/mediaControls/MediaControls.qml`.
  Spams `ReferenceError: filterDuplicatePlayers is not defined` on every media update.
  Untouched by this fork — worth an upstream issue or PR.

---

## Planned

- [ ] **Neon / liquid-glass widget styling** — heavy translucency plus glowing edges,
      built on the existing `appearance.transparency` system and the `FastBlur` +
      `OpacityMask` pattern already used by `UserCardWidget`. Opt-in, default off,
      so it changes nothing unless deliberately enabled.
- [ ] **yt-dlp widget** — still to do.
