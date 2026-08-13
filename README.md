# nix-conf

## Overview

`nix-conf` is a declarative NixOS configuration for a desktop host and a Dell Latitude laptop. The system layer is composed with flake-parts and NixOS modules. The user session is built from Hyprland with UWSM, the end-4 illogical-impulse QuickShell shell, and Matugen-generated runtime colors.

| Area | Location | Responsibility |
|---|---|---|
| Flake and pinned inputs | `flake.nix`, `flake.lock` | Defines public outputs and pins system, Home Manager, QuickShell, end-4, browser, editor, and application data inputs. |
| Host composition | `modules/hosts/` | Selects hardware, host identity, and machine-specific policy. |
| System features | `modules/features/` | Provides Hyprland/UWSM, portals, audio, greeter, hardening, containers, virtualization, development, and Flatpak capabilities. |
| User profile | `home/livara/` | Owns applications, Hyprland session settings, end-4 integration, Matugen adapters, Xournal++ flow, and user synchronization services. |
| End-4 assets | `inputs.illogical-impulse-dotfiles` | Provides the pinned immutable QuickShell, Hyprland, Matugen, Fuzzel, Hyprlock, and Wlogout source tree. |
| Editor | `inputs.vim-conf` | Provides the reusable NixVim module and editor policy. |
| Xournal++ | `inputs.xournal-conf` | Provides versioned application data without becoming a system module. |

## Desktop shell

The active desktop stack is **Hyprland + UWSM + QuickShell**, using the end-4 illogical-impulse profile named `ii`. `programs.hyprland.withUWSM = true` creates the supported login session, while Home Manager sets `wayland.windowManager.hyprland.systemd.enable = false` so UWSM remains the session lifecycle owner.

The end-4 source is pinned as a non-flake input. Immutable source assets are linked through Home Manager, while QuickShell-generated colors, wallpaper state, notifications, todos, and other runtime data remain writable under `~/.local/state/quickshell/user/generated/`. The integration does not run the end-4 installer and does not copy a complete mutable `.config` tree into the user home.

| Concern | Owner |
|---|---|
| Compositor, session entry, graphics prerequisites | `modules/features/hyprland.nix` |
| QuickShell and end-4 source assets | `modules/features/end4.nix` |
| Hyprland settings, compatibility shortcuts, screenshots, touchpad, and wallpaper startup | `home/livara/session.nix` |
| Runtime palette generation | Matugen and `home/livara/themes.nix` |
| Browser, GTK, ZenNotes, Xournal++, and NixVim adapters | `home/livara/themes.nix` and `home/livara/applications.nix` |

## Preserved shortcuts and screenshots

The local compatibility file is loaded after the upstream end-4 keybindings and explicitly unbinds conflicting defaults before restoring the historical nix-conf actions.

| Shortcut | Action |
|---|---|
| Super+Comma | QuickShell settings |
| Super+Space | QuickShell overview and launcher |
| Super+X | QuickShell session/power menu |
| Super+D | QuickShell overview/dashboard |
| Super+V | QuickShell clipboard history |
| Super+N / Super+O | ZenNotes |
| Super+Tab | QuickShell cheatsheet |
| Super+Shift+S | Region capture with `grim`, `slurp`, and `satty` |
| Super+S | Full output capture through `grimblast` |
| Super+Ctrl+S | Active window capture through `grimblast` |

The keyboard layout is `br`. Touchpad policy keeps tap-to-click, disable-while-typing, and natural scrolling enabled. The Xournal++ configuration remains application-owned and is synchronized through `scripts/sync-xournalpp-config.sh`.

## Themes

Matugen is the single runtime palette authority. Its stable output contract is:

| Output | Consumer |
|---|---|
| `~/.local/state/quickshell/user/generated/colors.json` | QuickShell |
| `~/.config/hypr/hyprland/colors.conf` | Hyprland |
| `~/.config/hypr/hyprlock.conf` | Hyprlock |
| `~/.config/fuzzel/fuzzel_theme.ini` | Fuzzel |
| `~/.config/gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` | GTK applications and Nautilus |
| `~/.local/state/nix-conf/theme/firefox.css` | Firefox profiles |
| `~/.local/state/nix-conf/theme/zen.css` | Zen Browser profiles |
| `~/.local/state/nix-conf/theme/zennotes.css` | ZenNotes |

These generated files must not be symlinked into the Nix store. Xournal++ keeps its reviewed semantic drawing configuration in `xournal-conf`; the GTK palette is consumed separately.

## Installation

The intended installed-system workflow uses the checkout at `~/.config/nixos` and requires no repository relocation:

```bash
cd ~/.config/nixos
./install.sh
```

The installer detects the selected host, generates or validates its tracked hardware configuration, runs `nix flake check --no-build`, and only then performs `nixos-rebuild switch`. Hardware failure stops the rebuild and, for Latitude, triggers the sanitized diagnostic collector when enabled.

To select a host without the prompt:

```bash
NIX_CONF_HOST=latitude ./install.sh
NIX_CONF_HOST=myMachine ./install.sh
```

To use the existing lockfile, leave `NIX_CONF_UPDATE_FLAKE` unset. Updating inputs is explicit:

```bash
NIX_CONF_UPDATE_FLAKE=1 ./install.sh
```

## Hardware generation

The unified generator supports the Latitude ext4 layout and the myMachine Btrfs layout:

```bash
cd ~/.config/nixos
sudo ./scripts/generate-hardware.sh --host latitude --dry-run
sudo ./scripts/generate-hardware.sh --host myMachine --dry-run
```

The generator uses `nixos-generate-config` when it can inspect the mounted system and falls back to mounted-kernel topology for Btrfs subvolume probing failures. It validates device references, preserves backups, stages only the selected tracked hardware file, and never formats disks, edits firmware settings, or adds ACPI kernel parameters.

## Validation

Run the following commands on a normal NixOS system or another host with Nix available. The sandbox used for repository analysis does not contain the Nix executable, so this is a required target-host gate:

```bash
nix flake lock
nix flake check --no-build
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
```

Run a test activation before switching when changing the shell or hardware:

```bash
sudo nixos-rebuild test --flake .#latitude
sudo nixos-rebuild test --flake .#myMachine
```

## Development, containers, and virtualization

The repository keeps shared workstation capabilities in system features and project-specific dependencies in focused devShells. The `python` shell provides the baseline for Python and Manim work; the `embedded` shell provides Arduino, PlatformIO, OpenOCD, probe-rs, and serial tooling. Rootless Docker, Compose, Buildx, libvirt, QEMU/KVM, SPICE, and virt-manager remain independent features and are not coupled to the desktop shell.

## References

- [end-4 illogical-impulse](https://github.com/xBLACKICEx/dots-hyprland/tree/tmp)
- [end-4 NixOS adapter](https://github.com/xBLACKICEx/end-4-dots-hyprland-nixos)
- [QuickShell](https://git.outfoxxed.me/outfoxxed/quickshell)
- [Hyprland on NixOS](https://wiki.hypr.land/Nix/Hyprland-on-NixOS/)
- [Matugen](https://github.com/InioX/matugen)
- [Home Manager manual](https://home-manager.dev/manual/)
- [NixOS module system](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [vim-conf](https://github.com/Joaoferraz-byte/vim-conf)
- [xournal-conf](https://github.com/Joaoferraz-byte/xournal-conf)
