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

---

## Planned

- [ ] **yt-dlp widget** — a background widget in the style of the existing Image Converter:
      paste a URL, auto-filled but editable output name, pick a container/format
      (`mp3` / `ogg` / `mp4` / …), download. Intended as an upstream PR.
- [ ] **Neon / translucent widget styling** — as an opt-in appearance toggle, default off,
      so it changes nothing unless deliberately enabled. Intended as an upstream PR,
      separately from the widget above.
