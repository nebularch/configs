# HyprV — Build Your Own Desktop the Way You Like

*For those who drank from the waters of Lethe.*

Think of this setup like walking into a buffet.

You walk in with an empty plate. The buffet has everything laid out: rice, vegetables, sauces, drinks, and desserts. You don't take everything just because it's there. You choose what you like, skip what you don't, and build a plate that suits you.

**Your Linux desktop works the same way.**

HyprV gives you a starting point, a collection of tools, and configurations that work together. You choose the components you need, leave out what you don't, and customize the result until it feels like your own.

No one's checking your plate. There is no mandatory dessert. And installing every package just because it's listed is a great way to discover what dependency hell tastes like.

---

## The buffet: What's on the menu?

Every desktop needs a few things to keep the kitchen running. Here's what's available in the HyprV setup.

| Package or group | What it does | Think of it as… |
|---|---|---|
| `hyprland` | The Wayland compositor that manages your windows and desktop layout | The dining hall itself |
| `kitty` | A terminal emulator for running commands | Your workspace for preparing things |
| `waybar` | A customizable bar for system information, workspaces, and controls | The display board above the buffet |
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
| `starship` | Customizes your shell prompt; optional integration | Your personalized nameplate |
| `ttf-jetbrains-mono-nerd` + `noto-fonts-emoji` | Provide fonts and symbols used by desktop themes | The typography and symbols on the menu |
| `lxappearance` + `xfce4-settings` + `nwg-look` | Provide graphical appearance and settings tools | Choosing the tableware and finishing touches |
| `sddm` | Provides a display manager for graphical login | The entrance to your dining hall |
| `qt5-wayland` + `qt6-wayland` | Provide Wayland integration for Qt applications | Making sure different dishes fit the table |
| `qt5ct` + `qt6ct` | Provide Qt application appearance settings | Choosing how the tableware looks |
| `pipewire` + `wireplumber` | Provide audio and multimedia services | The kitchen's sound and service system |
| `wl-clipboard` + `cliphist` | Provide clipboard access and clipboard history | Your tray for carrying things around |
| `firefox` + `thunderbird` + `mpv` | Provide web browsing, email, and media playback | The reading corner, post counter, and entertainment area |
| `papirus-icon-theme` | Provides an icon theme | The visual style of the menu |
| `qt5-svg` + `qt5-quickcontrols2` + `qt5-graphicaleffects` + `gtk3` | Provide graphical toolkit components and dependencies | The kitchen equipment behind the scenes |
| `xdg-desktop-portal-hyprland` | Provides desktop portal integration for supported Wayland applications | The service desk connecting different parts of the dining hall |

These are practical analogies, not exact technical equivalents. Some components depend on other services, packages, or configuration, and some are useful only if you want the feature they provide.

**One important distinction: this menu describes the broader HyprV desktop, not the installer's exact package list.**

Think of the menu as a map of the kitchen. It shows the tools and ingredients that make up the desktop experience. The actual package definitions used by the installer live separately in `installer/packages/packages.sh`.

That manifest defines the installer's package groups, including base packages, desktop packages, and optional integrations such as Starship and ASUS ROG support. The package manager then checks package availability and classifies packages according to their repository and installation status.

So, a package appearing in this README doesn't necessarily mean it will be installed on every machine. Some are optional, some belong to specific integrations, and the installer handles package selection separately.

The menu shows you what's part of the experience. The manifest tells the installer what to consider installing. Two related things, but not the same thing.

## Your plate, your rules

You don't have to install every item just because it appears on the menu.

- **A minimal plate:** Hyprland, a terminal, a launcher, and only the essential tools you need.
- **A comfortable plate:** Add Waybar, notifications, a file manager, audio controls, and Bluetooth support.
- **A fully loaded plate:** Add screenshot tools, media applications, custom fonts, optional shell integrations, and the other utilities you want.

These are examples, not strict installation profiles. Your hardware, workflow, and preferences determine what belongs on your plate.

And remember: removing a package doesn't automatically remove its configuration or disable the feature that depends on it. Linux is very good at following instructions. It is not particularly good at guessing what you meant.

## How to choose your ingredients

Want to know what the installer actually works with? That's where the package manifest comes in.

The installer's package definitions live here:

```text
installer/
└── packages/
    ├── packages.sh
    └── manager.sh
```

`packages.sh` defines the package groups and their contents. `manager.sh` handles package discovery, availability checks, and classification.

The current manifest separates packages into:

| Package group | Purpose |
|---|---|
| Base packages | General desktop dependencies and utilities |
| Desktop packages | HyprV, desktop applications, and everyday tools |
| Starship packages | Optional shell prompt integration |
| ROG packages | Optional ASUS ROG hardware support |
| AUR packages | Packages checked for AUR availability |

The package manager checks availability and classifies packages according to their installation and repository status. This helps the installer understand what is available before making an installation decision.

In short:

- **README menu:** An overview of the broader desktop and its components.
- **Package manifest:** The actual package definitions used by the installer.
- **Package manager:** The logic that checks and classifies those packages.

No mysterious package soup. The definitions and the logic that processes them have separate responsibilities.

## Meet the configuration

HyprV started with a traditional Hyprland configuration and has since grown into a modular setup using Lua.

Instead of keeping every setting in one enormous configuration file, the Lua setup divides responsibilities into smaller modules.

Because debugging one giant file is an excellent way to lose an afternoon.

### The Lua setup

The public configuration lives in:

```text
HyprV/
└── hypr/
    ├── hyprland.lua
    └── lua/
        ├── init.lua
        ├── settings.lua
        ├── environment.lua
        ├── monitors.lua
        ├── input.lua
        ├── animations.lua
        ├── layouts.lua
        ├── windowrules.lua
        ├── gestures.lua
        ├── keybinds.lua
        ├── media.lua
        ├── autostart.lua
        ├── nvidia.lua
        └── rog.lua
```

Each module has a specific job:

| Module | Responsibility |
|---|---|
| `init.lua` | Loads the configuration modules |
| `settings.lua` | General Hyprland settings |
| `environment.lua` | Environment variables |
| `monitors.lua` | Monitor configuration |
| `input.lua` | Keyboard, mouse, and input settings |
| `animations.lua` | Window and workspace animations |
| `layouts.lua` | Layout behavior |
| `windowrules.lua` | Window rules |
| `gestures.lua` | Gesture configuration |
| `keybinds.lua` | Keyboard shortcuts |
| `media.lua` | Media and multimedia bindings |
| `autostart.lua` | Startup applications and services |
| `nvidia.lua` | Optional NVIDIA-specific configuration |
| `rog.lua` | Optional ASUS ROG configuration |

The optional hardware modules are kept separate so users don't have to carry hardware-specific settings they will never use.

### Private configuration

A shared configuration should not assume that every machine has the same monitors, keyboard, GPU, or preferences.

Machine-specific settings can live outside the public repository, using private overrides.

For example:

```text
~/.config/hypr/
├── hyprland.lua
├── hyprv/
│   └── ...
└── hyprv-private/
    ├── features.lua
    └── monitors.lua
```

The public modules remain reusable, while private settings handle the peculiarities of an individual machine.

Your monitor arrangement is yours. It doesn't need to become everybody else's problem.

### The legacy CONF configuration

The repository also retains the traditional Hyprland `.conf` configuration as a separate strategy.

The Lua and CONF configurations are two different approaches. The legacy configuration remains available for reference and compatibility work; it is not the source of the active Lua setup.

The CONF strategy currently validates its required files. Its deployment mapping is still under development.

## The rest of the desktop

HyprV isn't just a compositor configuration. The surrounding tools and scripts help bring the desktop together.

### Waybar

Waybar handles the status bar, workspaces, system information, and desktop controls.

HyprV includes multiple visual profiles, allowing the bar's appearance and layout to change without manually rebuilding the entire configuration every time.

### HyprV utility

The `hyprv_util` Bash script coordinates desktop profile switching and related visual changes.

It handles things such as:

- Switching Waybar configuration and styling.
- Changing Wofi styling.
- Managing wallpaper-related changes.
- Applying the selected visual profile.

One important distinction: these are desktop appearance profiles. They do not switch the underlying Hyprland Lua configuration.

### Supporting tools

The repository also includes configurations and scripts for Wofi, Mako, wallpapers, screenshot utilities, session menus, and other desktop components.

Lua handles the compositor configuration. Bash handles a number of supporting utilities. Waybar handles the status bar.

Different tools, different jobs. Everyone stays in their lane. Mostly.

## The installer

The installer is being developed as a modular Bash project rather than one enormous script that does everything.

The idea is simple: separate responsibilities, make behavior easier to understand, and test individual components before connecting them.

```text
installer/
├── core/
│   ├── backup.sh
│   ├── logging.sh
│   ├── preflight.sh
│   ├── restore.sh
│   └── ui.sh
├── deployment/
│   ├── executor.sh
│   ├── manifest.sh
│   ├── planner.sh
│   └── rollback.sh
├── packages/
│   ├── manager.sh
│   └── packages.sh
├── strategies/
│   ├── conf.sh
│   ├── lua.sh
│   └── manager.sh
├── tests/
│   └── run.sh
└── main.sh
```

### What does what?

| Component | Responsibility |
|---|---|
| `core/` | Logging, preflight checks, backup and restore support, and user interaction |
| `packages/` | Package definitions and package availability checks |
| `strategies/` | Selection and validation of Lua or CONF configurations |
| `deployment/` | Deployment planning, execution, and rollback components |
| `tests/` | Automated tests for installer behavior |
| `main.sh` | Main installer entry point |

### Configuration strategies

The installer supports selecting between Lua and CONF configuration strategies.

The Lua strategy currently maps:

```text
HyprV/hypr/hyprland.lua
    → ~/.config/hypr/hyprland.lua

HyprV/hypr/lua/
    → ~/.config/hypr/hyprv/
```

This keeps the public Lua modules separate from the user's main Hyprland configuration entry point.

The installer is also designed to preserve machine-specific configuration rather than blindly replacing private settings.

### Deployment planning

Before deployment, the planner examines the intended destination and classifies what it finds.

| Status | Meaning |
|---|---|
| `MISSING` | The destination does not exist |
| `MATCH` | An existing symlink resolves to the intended source |
| `IDENTICAL` | An existing regular file has identical content |
| `CONFLICT` | The destination differs from the intended source or presents a safety issue |

The goal is to discover problems before touching existing configuration files.

The deployment executor and rollback components have also been developed and tested independently. They are not yet connected to the main installer execution flow.

In other words, the safety machinery is being built, but the main installer isn't pretending to be further along than it is.

## Current development status

> **Planning-only milestone**

The current `installer/main.sh` performs:

- Preflight checks.
- Configuration strategy selection.
- Optional feature selection.
- Package planning and classification.
- Deployment planning.
- A summary and user confirmation.

At this milestone, the main entry point does **not** install packages, deploy configuration files, or modify hardware settings.

The executor and rollback components exist separately, but full integration is still in progress.

The project is being developed incrementally, with safety checks and automated tests forming part of the process.

## Installation and testing

### 1. Get the repository

```bash
git clone https://github.com/nebularch/configs.git
cd configs
```

### 2. Have a look around

Before running anything, take a look at the installer and its components.

```bash
less installer/main.sh
```

You can also inspect the package definitions and configuration strategies:

```bash
less installer/packages/packages.sh
less installer/strategies/lua.sh
less installer/strategies/conf.sh
```

Reading the code before running it is not paranoia. It's just a good habit. Especially when `sudo` is involved.

### 3. Run the current planning milestone

```bash
bash installer/main.sh
```

This runs the current planning-only workflow. It performs checks, builds a package and deployment plan, and presents a summary.

It does not install packages or deploy configurations.

### 4. Run the tests

```bash
bash installer/tests/run.sh
```

The test suite checks the installer components and their expected behavior.

If you're changing the installer, run the tests before committing your changes. Your future self will appreciate it. Your future self is usually the person who gets blamed.

## Hardware-specific configuration

Not every machine needs the same ingredients. Hardware-specific support is kept separate from the general desktop setup.

### NVIDIA

NVIDIA configuration depends on the GPU generation, kernel, driver, and boot setup.

The installer does not currently define a universal NVIDIA driver package selection. Driver support is intentionally kept separate until the appropriate package and configuration choices can be made safely.

Check the current Arch Linux documentation and your GPU's compatibility before configuring NVIDIA support.

### ASUS ROG

Optional ASUS ROG integration is defined separately in the package manifest:

```text
asusctl
supergfxctl
rog-control-center
```

These packages are intended for supported hardware. They are not mandatory desktop dependencies.

## Make it yours

Configuration is not a monument. It is a conversation between the machine and the person using it.

Change a keybinding. Remove a module. Try a different layout. Keep a backup before experimenting, and commit changes you want to preserve.

If you find a better way to do something, make the improvement part of your setup.

And if something breaks? Well, congratulations. You've found a new learning opportunity. Probably.

## Contributing

HyprV is a work in progress. Improvements, fixes, and ideas are welcome.

A few things make contributions easier to review and maintain:

- Keep changes focused and easy to understand.
- Test changes before submitting them.
- Avoid committing machine-specific settings or personal files.
- Document new dependencies and optional features.
- Preserve existing user configurations when changing installer behavior.
- Review your diff before committing. Git is not a time machine if you never committed the thing you wanted to keep.

Small, deliberate changes are easier to understand than one enormous commit titled `final-final-actually-final`.

## Credits and acknowledgements

HyprV originally started as a customization of [SolDoesTech's HyprV4](https://github.com/SolDoesTech/HyprV4), which provided the foundation for the original desktop configuration and installation workflow.

Since then, the project has grown through personal modifications, custom Waybar layouts, desktop utilities, multiple visual profiles, and a modular Lua-based Hyprland configuration.

The installer has also evolved into a modular system with configuration strategies, package planning, deployment safety checks, rollback components, and automated tests.

A big thank you to SolDoesTech for the original work and inspiration behind this project.

## A note on licensing

The original `set-hypr` script contains a header from SolDoesTech permitting copying, editing, and distribution of that script.

That statement should not be assumed to define the license for every file in this repository. Check the applicable upstream terms for reused material.

## A small note

These configurations are a collection of choices, not universal rules. Your hardware, workflow, and preferences may differ.

Take what helps. Leave what doesn't.

The goal isn't to install the biggest plate.

**The goal is to build a desktop that feels like yours.**

Take what you need. Leave what you don't. Learn what each piece does. Then make it your own.
