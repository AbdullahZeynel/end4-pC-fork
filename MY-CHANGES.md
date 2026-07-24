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

---

## Planned

- [ ] **yt-dlp widget** — a background widget in the style of the existing Image Converter:
      paste a URL, auto-filled but editable output name, pick a container/format
      (`mp3` / `ogg` / `mp4` / …), download. Intended as an upstream PR.
- [ ] **Neon / liquid-glass widget styling** — heavy translucency plus glowing edges,
      built on the existing `appearance.transparency` system and the `FastBlur` +
      `OpacityMask` pattern already used by `UserCardWidget`. Opt-in, default off,
      so it changes nothing unless deliberately enabled.
- [ ] **City widget** — one city's time and weather merged into a single widget with a
      photo background, replacing the four-timezone World Clock and the separate Weather
      widget. Image path configurable; no image bundled in the repo.
