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
- **A comfortable plate:** Add Waybar, notifications, a file manager, audio controls, and Bluetooth support.
- **A fully loaded plate:** Add screenshot tools, themed login screens, custom fonts, power-profile switching, and the other utilities you want.

These are examples, not strict installation profiles. Your hardware, workflow, and preferences determine what belongs on your plate.

## How to choose your ingredients

The following command represents the package selection used by this configuration.

```bash
yay -S hyprland kitty jq mako waybar-hyprland \
  awww swaylock-effects wofi wlogout \
  xdg-desktop-portal-hyprland swappy grim slurp thunar \
  polkit-gnome python-requests pamixer pavucontrol \
  brightnessctl bluez bluez-utils blueman \
  network-manager-applet gvfs thunar-archive-plugin \
  file-roller btop pacman-contrib starship \
  ttf-jetbrains-mono-nerd noto-fonts-emoji \
  lxappearance xfce4-settings sddm-git \
  sddm-sugar-candy-git power-profiles-daemon
```

Here's how to read it:

- `yay -S` asks `yay` to install the packages that follow.
- Every package name is an ingredient you're asking to add to your system.
- The `\` characters let the command continue onto the next line; they aren't package names.
- You can remove packages you don't want, but first check whether the configuration or scripts rely on them.
- You can add other compatible tools if they suit your workflow.

**Important:** Removing a package from this command doesn't automatically remove its configuration, disable related modules, or replace its functionality. If you skip something, check for references to it in your Hyprland, Waybar, and other configuration files.

## Before you serve

This configuration was originally intended for a **clean, fresh Arch Linux installation on physical hardware**.

Before installing:

- Review the packages `yay` proposes before confirming.
- Check that packages are available from your configured repositories or AUR sources.
- Remember that Git-based packages and themed variants may change or become unavailable.
- Check whether your hardware supports the features you want to use.
- Back up existing configurations before replacing them.
- Review installation scripts before allowing them to modify your system.

This is a starting selection, not a universal recipe.

## Installation

### 1. Get the repository

```bash
git clone https://github.com/nebularch/configs.git
cd configs
```

### 2. Review the installer

The repository includes the `set-hypr` installation script.

Inspect it before running:

```bash
less set-hypr
```

Review its package list, file-copy operations, configuration changes, and any commands that modify system settings. Follow the instructions provided by the script and run it only when you understand the changes it will make.

You can also use the repository as a reference and install or configure the components manually.

### 3. NVIDIA users

NVIDIA setup depends on your GPU, kernel, driver, boot configuration, and installed packages.

The original guide used the following commands as part of its NVIDIA setup:

Install the relevant packages:

```bash
yay -S linux-headers nvidia-dkms qt5-wayland qt5ct \
  libva libva-nvidia-driver-git
```

Configure the NVIDIA DRM option:

```bash
echo "options nvidia-drm modeset=1" | \
  sudo tee /etc/modprobe.d/nvidia.conf
```

Verify the configuration:

```bash
cat /etc/modprobe.d/nvidia.conf
```

The expected setting in that original guide is:

```text
options nvidia-drm modeset=1
```

**Do not treat these commands as universal NVIDIA installation instructions.** Verify the current Arch Linux NVIDIA documentation and choose the appropriate driver and kernel configuration for your hardware before proceeding.

The original guide also modified `/etc/mkinitcpio.conf`, added NVIDIA modules, generated an initramfs image, and rebooted. Those steps are not reproduced as a blind copy-and-paste procedure here because the correct initramfs and boot configuration depend on your system. Back up your configuration and confirm the correct procedure before making those changes.

## Make it yours

Configuration is not a monument. It is a conversation between the machine and the person using it.

Change a keybinding. Remove a module. Try a different layout. Keep a backup before experimenting, and commit changes you want to preserve.

If you find a better way to do something, make the improvement part of your setup.

## A small note

These configurations are a collection of choices, not universal rules. Your hardware, workflow, and preferences may differ.

Take what helps. Leave what doesn't.

The goal isn't to install the biggest plate.

**The goal is to build a desktop that feels like yours.**

Take what you need. Leave what you don't. Learn what each piece does. Then make it your own.
