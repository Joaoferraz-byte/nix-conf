# NixOS and Home Manager modules

This directory contains the evaluated NixOS and flake-parts modules for the repository. The root [README](../README.md) describes the user-facing workflow, while [ARCHITECTURE.md](../ARCHITECTURE.md) records broader architectural decisions and validation rules.

| Path | Responsibility |
|---|---|
| `features/` | Reusable system capabilities such as Niri, portals, audio, drivers, hardening, Flatpak, containers, virtualization and development tools. |
| `packages/` | Shared package sets and compatibility definitions. |
| `hosts/` | Machine composition roots, hardware declarations, locale, identity and host-specific policy. |
| `parts.nix` | flake-parts definitions for public module exports and shared flake metadata. |

The root `flake.nix` imports the evaluated module surface explicitly. A reusable feature must expose a stable `flake.nixosModules.<name>` or `flake.homeModules.<name>` contract at the layer where its options are evaluated.

## Shared desktop profile

`hosts/common-desktop.nix` is a composition module. It imports Home Manager, the Niri system module, the Noctalia integration, shell-independent application support, Stylix and NixVim. The `home/livara/` profile is split by ownership:

| File | Owner |
|---|---|
| `home.nix` | Thin profile entrypoint, identity, imports and stable user preferences. |
| `niri.nix` | Niri input, navigation, workspace actions, compositor policy and Noctalia IPC keybinds. |
| `monitors.nix` | Host-specific output rules; `myMachine` intentionally uses runtime monitor discovery. |
| `session.nix` | Session directories and user-session boundaries; shell idle/lock policy belongs to Noctalia. |
| `themes.nix` | Stylix cursor boundary, Kora icon policy and stable desktop appearance. |
| `applications.nix` | Applications, XDG associations, NixVim and browser profile contracts. |
| `sync.nix` | Independent Vault synchronization service and timer; wallpapers remain local Noctalia data. |

## Noctalia and visual API

Noctalia v5 is the sole user-facing shell, started exactly once by Niri through `spawn-at-startup`. Its Home Manager module supplies the bar, launcher, panels, notifications, wallpaper, widgets, plugin registry and documented IPC. The `noctalia-conf` flake pins the shell and plugin revisions and installs stable user templates from the store.

The central theme flow is:

> Local wallpaper in `~/Wallpapers` → Noctalia v5 `m3-fruit-salad` palette/templates → `$XDG_STATE_HOME/livara/theme/palette.dark.json` → shell-conf application adapters.

Noctalia owns native GTK, Qt, Firefox, Zen Browser, WezTerm, Kitty, Starship and KDE contracts. `shell-conf` materializes only formats not covered by those templates, including Freesm Launcher, Heroic, Foliate, Xournal++ and Vesktop. The Livara Home Manager profile provides Nautilus, cmus and local Books/Games/Musics directories. Generated state is mutable runtime data and is never copied into the source tree.

The selected plugin set is vendored and pinned by `noctalia-conf`: `cat`, `timer`, `screen_recorder`, `screen_toolkit`, `gamer_mode`, the FreeSM-adapted `prismlauncher_instances` provider and `bitwarden`. The screen recorder consumes the system-provided `gpu-screen-recorder` capability, while Screen Toolkit receives its Wayland/OCR/annotation tools from `features/niri.nix`. Plugin source is immutable; plugin settings and runtime state remain user data.

`vim-conf` owns the Nixvim editor, Markdown rendering, Mermaid/LaTeX workflow and keymaps; Nautilus owns native desktop file browsing. The `Vault` repository owns plain Markdown and Xournal++ notes; `nix-conf` owns its generic Git synchronization, while `shell-conf` supplies shared palette and application adapters without writing editor state into the Vault. Tablet presence is reported from the physical USB identity and remains separate from the driver/udev module. Battery, Bluetooth, NVIDIA, audio, portals, keyd and power profiles remain host/system responsibilities.

`stylix` is intentionally narrow: it provides the Bibata-Modern-Classic cursor and stable session variables. It is not treated as a universal application theme engine; color ownership remains centralized in Noctalia and each adapter follows its target application's documented format.

## Input and rebuild boundaries

The XKB of Niri, system locale, console keymap and keyd are separate layers. `features/keyd.nix` owns external Aitek Delta TM6101 remapping; Niri owns compositor navigation and Noctalia actions. The modules must not redefine the same physical key in unrelated layers without an explicit host condition.

`install.sh` owns the normal workflow. It refuses to run as root, checks Git permissions and conflict state, validates or reuses hardware, runs the low-cost flake checks, evaluates the selected system derivation and invokes `nixos-rebuild` only after those gates pass. The hardware generator supports ext4 and Btrfs without formatting, repartitioning, guessing devices or changing ACPI parameters.

## Validation

The minimum gate for a feature or host change is:

```bash
git diff --check
find scripts -maxdepth 1 -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
sudo nix-instantiate --parse home/livara/home.nix
sudo nix-instantiate --parse home/livara/niri.nix
sudo nix-instantiate --parse modules/hosts/common-desktop.nix
```

Then evaluate or build each affected host on a machine with sufficient Nix store capacity:

```bash
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
```

On the real host, run `niri validate`, `noctalia msg plugins list`, the generated palette/application checks, `keyd check`, and the hardware/audio/portal checks. A constrained sandbox can establish syntax and graph consistency but cannot prove visual behavior, GPU capture, monitor discovery or lock/suspend behavior on physical hardware; use direct read-only commands for those checks rather than a repository-specific collector.
