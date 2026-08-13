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

## Installation and rebuild flow

The intended installed-system workflow uses the checkout at `~/.config/nixos` and requires no repository relocation. Run the installer as `livara`, not as root:

```bash
cd ~/.config/nixos
./install.sh
```

The installer performs a preflight before entering the development shell. It verifies that the checkout is a Git worktree owned by the current user, that `.git/objects` and the index are writable, that there are no unresolved conflicts or `flake.lock` conflict markers, and that the required Nix commands are available. It then validates or reuses hardware, checks the flake without changing the lockfile, evaluates the selected system derivation, and only then invokes `nixos-rebuild`.

The default mode is `switch`. Safer modes are available through `NIX_CONF_REBUILD_MODE`:

| Mode | Effect |
|---|---|
| `dry-activate` | Builds the system and reports activation changes without activating it. |
| `test` | Builds and activates the generation without making it the bootloader default. |
| `boot` | Builds and selects the generation for the next boot without activating it now. |
| `switch` | Builds, creates a generation, updates the boot default, and activates immediately. |

For a first end-4 or hardware test, use `dry-activate` or `test` before `switch`:

```bash
NIX_CONF_HOST=latitude NIX_CONF_REBUILD_MODE=dry-activate ./install.sh
NIX_CONF_HOST=latitude NIX_CONF_REBUILD_MODE=test ./install.sh
NIX_CONF_HOST=latitude ./install.sh
```

To select a host without the prompt:

```bash
NIX_CONF_HOST=latitude ./install.sh
NIX_CONF_HOST=myMachine ./install.sh
```

The existing `flake.lock` is used by default. The installer never updates inputs during its `nix develop` bootstrap or normal check. Update inputs only by explicit request, optionally selecting input names:

```bash
NIX_CONF_UPDATE_FLAKE=1 ./install.sh
NIX_CONF_UPDATE_FLAKE=1 NIX_CONF_UPDATE_INPUTS='quickshell illogical-impulse-dotfiles' ./install.sh
```

The installer backs up `flake.lock` before an explicit update. It does not pull Git branches automatically, because pulling over local hardware or Xournal++ changes can create conflicts that must be resolved deliberately. Preserve local work before synchronizing:

```bash
git status --short
git stash push -u -m 'local changes before nix-conf sync'
git fetch origin main
git merge --ff-only origin/main
nix flake check --no-build --no-update-lock-file
git stash pop
```

If `git stash pop` reports a conflict, do not use `git reset --hard` or delete the conflict files. Keep the stash entry and resolve only the affected files.

## Hardware generation

The unified generator supports the Latitude ext4 layout and the myMachine Btrfs layout. Run it as the checkout owner; it invokes `sudo` only when it must mount an existing ESP:

```bash
cd ~/.config/nixos
./scripts/generate-hardware.sh --host latitude --dry-run
./scripts/generate-hardware.sh --host myMachine --dry-run
```

When a tracked hardware file has local modifications, the generator validates and reuses it instead of overwriting it. Set `NIX_CONF_ALLOW_HARDWARE_REPLACE=1` only after reviewing a backup and intentionally requesting regeneration. The generator uses `nixos-generate-config` when it can inspect the mounted system and falls back to mounted-kernel topology for Btrfs subvolume probing failures. It validates device references, preserves backups, stages only the selected tracked hardware file, and never formats disks, edits firmware settings, or adds ACPI kernel parameters.

## Validation

Run the following commands on a normal NixOS system or another host with Nix available. The sandbox used for repository analysis does not contain the Nix executable, so this is a required target-host gate:

```bash
git diff --check
nix flake check --no-build --no-update-lock-file --show-trace
nix eval --raw --no-update-lock-file '.#nixosConfigurations.latitude.config.system.build.toplevel.drvPath'
nix eval --raw --no-update-lock-file '.#nixosConfigurations.myMachine.config.system.build.toplevel.drvPath'
nix build --no-update-lock-file '.#nixosConfigurations.latitude.config.system.build.toplevel'
nix build --no-update-lock-file '.#nixosConfigurations.myMachine.config.system.build.toplevel'
```

Use `nix flake lock` only after adding inputs and use `nix flake update <input>` only when intentionally changing a pinned revision. A successful `nix flake check --no-build` proves evaluation and output shape, not activation; `nix eval` prints a derivation path but does not build or activate it.

For recovery after an activation failure, list generations and select the previous generation:

```bash
sudo nixos-rebuild list-generations
sudo nixos-rebuild --rollback switch
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
