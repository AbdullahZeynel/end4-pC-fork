<div align="center">

# 💠 end4-pC-fork

**A personal fork of [end4-pC](https://github.com/pctrade/end4-pC) by [@pctrade](https://github.com/pctrade)**
which is itself a fork of [illogical-impulse](https://github.com/end-4/dots-hyprland) by [@end-4](https://github.com/end-4)

Customized and maintained by **[@AbdullahZeynel](https://github.com/AbdullahZeynel)**

</div>

---

## 📸 Screenshots

<div align="center">

| 🎵 Lyrics | 🖼️ Online Wallpapers |
|:---:|:---:|
| ![Screenshot 1](screenshots/1.png) | ![Screenshot 2](screenshots/2.png) |
| 🪟 Desktop Widgets | 🔧 Hyprland Configs |
| ![Screenshot 5](screenshots/5.png) | ![Screenshot 6](screenshots/6.png) |
| ⚙️ Configurable Bar | ✨ And More |
| ![Screenshot 3](screenshots/3.png) | ![Screenshot 4](screenshots/4.png) |

</div>

---

## 🌱 What this fork is

This is my personal rice. It tracks [pctrade/end4-pC](https://github.com/pctrade/end4-pC) and adds
my own changes on top. See **[MY-CHANGES.md](MY-CHANGES.md)** for what I've actually altered.

Everything that makes this shell good was built by [@end-4](https://github.com/end-4) and
[@pctrade](https://github.com/pctrade) — I'm standing on their work. If you're looking for the
real thing rather than one person's tweaks, go to their repos.

### Branches

| Branch | Purpose |
|:---|:---|
| `main` | Untouched mirror of upstream. Never committed to directly. |
| `mine` | My rice. This is what I actually run. |
| `feat/*` | Individual features branched off `main`, intended as upstream pull requests. |

`git diff main..mine` shows exactly what I changed and nothing else.

---

## ⚡ Installation

> [!NOTE]
> This fork manages its own configuration folder independently — it does **not** overwrite or
> modify any existing setup. However, it does require
> [illogical-impulse](https://github.com/end-4/dots-hyprland) to be installed and running.

```bash
cd ~/.config/quickshell/
git clone https://github.com/AbdullahZeynel/end4-pC-fork.git
killall qs 2>/dev/null; qs -c end4-pC-fork > /dev/null 2>&1 & disown
```

### 🔧 Set as your default shell (optional)

If you like it and want it to load by default instead of `ii`, edit:

```bash
~/.config/hypr/hyprland/variables.lua
```

And change this line:

```lua
hl.env("qsConfig", "ii")
```

to:

```lua
hl.env("qsConfig", "end4-pC-fork")
```

> [!TIP]
> After saving, restart Hyprland or run `hyprctl reload` to apply the change.

---

### ⚙️ Settings keybind

To open the settings panel, add this to your Hyprland config:

```lua
hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), {description = "Toggle settings"})
```

> **Note:** Settings is an overlay panel, not a regular window — `Super + Q` won't close it.
> Use the same keybind to toggle it or press `Escape`.

---

## 🙏 Credits

Huge thanks to the people who made this possible:

- **[@end-4](https://github.com/end-4)** — for creating the original [dots-hyprland](https://github.com/end-4/dots-hyprland) / illogical-impulse shell. An absolute masterpiece of a dotfiles project 🫡
- **[@pctrade](https://github.com/pctrade)** — for [end4-pC](https://github.com/pctrade/end4-pC), the fork this one is built on, and for the widget system, settings panels and countless refinements 🙏
- **[@gh0stzk](https://github.com/gh0stzk)** — for providing the weather API integration that made the weather widget possible 🙌
- **[@StarS2112](https://github.com/StarS2112)** — for showcasing the upstream fork 🙌

---

## 📄 License

[GPL-3.0](LICENSE), inherited from upstream. Same license, same freedoms — fork it further if you like.

---

<div align="center">

Made with ❤️ — feel free to fork and make it your own

</div>
