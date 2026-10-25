# Build your own desktop the way you like

*For those who drank from the waters of Lethe.*

Think of this setup like walking into a buffet.

You walk in with an empty plate. The buffet has everything laid out: rice, vegetables, sauces, drinks, and desserts. You don't take everything just because it's there. You choose what you like, skip what you don't, and build a plate that suits you.

**Your Linux desktop works the same way.**

HyprV4 gives you a starting point, a collection of tools, and configurations that work together. You choose the components you need, leave out what you don't, and customize the result until it feels like your own.

---

## The buffet: What's on the menu?

| Package or group | What it does | Think of it as… |
|---|---|---|
| `hyprland` | The Wayland compositor that manages your windows and desktop layout | The dining hall itself |
| `kitty` | A terminal emulator for running commands | Your workspace for preparing things |
| `waybar-hyprland` | A customizable bar for system information, workspaces, and controls | The display board above the buffet |
| `mako` | Shows desktop notifications | Someone calling your order number |
| `wofi` | A launcher for opening apps and running commands | The menu where you choose what you want |
| `wlogout` | Provides a graphical logout, reboot, and shutdown menu | The exit counter |
| `awww` | Handles wallpaper display and transitions | The decoration that gives the room its atmosphere |
| `swaylock-effects` | Locks your screen | Closing your table when you step away |
| `grim` + `slurp` | Capture screenshots, including selected screen regions | Taking a picture of your plate |
| `swappy` | Lets you annotate screenshots | Adding notes to the picture |
| `thunar` | A graphical file manager | The storage room where you organize your things |
| `pavucontrol` + `pamixer` | Graphical and command-line audio controls | Adjusting the volume of the music |
| `brightnessctl` | Controls display or supported device brightness | Adjusting the room's lighting |
| `bluez` + `bluez-utils` + `blueman` | Bluetooth support and device management | Connecting your wireless accessories |
| `network-manager-applet` | Provides a graphical network-management interface | The Wi-Fi counter |
| `gvfs` + `thunar-archive-plugin` + `file-roller` | Support for file-manager integrations and archive handling | The tools for unpacking and organizing deliveries |
| `polkit-gnome` | Provides graphical authentication prompts for supported privileged actions | The staff member who verifies permission |
| `jq` | Reads and processes JSON data in scripts | A tool for sorting structured information |
| `python-requests` | Gives Python scripts an HTTP client library | A helper for scripts that communicate over the internet |
| `btop` | Displays system resource usage | The kitchen's live activity monitor |
| `pacman-contrib` | Adds useful Arch package-management utilities | Extra maintenance tools |
| `starship` | Customizes your shell prompt | Your personalized nameplate |
| `ttf-jetbrains-mono-nerd` + `noto-fonts-emoji` | Provide fonts and symbols used by many desktop themes | The typography and symbols on the menu |
| `lxappearance` + `xfce4-settings` | Provide graphical appearance and settings tools | Choosing the tableware and finishing touches |
| `sddm-git` + `sddm-sugar-candy-git` | Provide a login manager and a themed login screen | The entrance to your dining hall |
| `power-profiles-daemon` | Provides power profiles on supported hardware | Choosing between saving energy and prioritizing performance |

These are practical analogies, not exact technical equivalents. Some components depend on other services, packages, or configuration, and some are useful only if you want the feature they provide.

## Your plate, your rules

You don't have to install every item just because it appears on the menu.

- **A minimal plate:** Hyprland, a terminal, a launcher, and only the essential tools you need.
- **A comfortable plate:** Add Waybar, notifications, a file manager, audio controls, and Bluetooth
