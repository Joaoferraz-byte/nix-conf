# NixOS Module Layout

This directory contains the evaluated NixOS and flake-parts modules for the repository. The root [README](../README.md) describes the user-facing workflow, while [ARCHITECTURE.md](../ARCHITECTURE.md) records broader architectural decisions and validation rules.

| Path | Responsibility |
|---|---|
| `features/` | Reusable system capabilities such as niri, portals, audio, drivers, hardening, Flatpak, containers, virtualization, and development tools. |
| `packages/` | Shared package sets and compatibility definitions. |
| `hosts/` | Machine composition roots, hardware declarations, locale, identity, and host-specific policy. |
| `parts.nix` | flake-parts definitions for public module exports and shared flake metadata. |

The root `flake.nix` imports the evaluated module surface explicitly. Files under `archive/` are historical and remain outside the evaluated tree. A reusable feature must expose a stable `flake.nixosModules.<name>` or `flake.homeModules.<name>` contract at the layer where its options are evaluated.

## Shared desktop profile

`hosts/common-desktop.nix` is a composition module. It imports Home Manager, the niri system module, the `shell-conf` Home Manager module, the pinned DMS Home Manager module, and the NixVim module. The `home/livara/` profile is split by ownership:

| File | Owner |
|---|---|
| `home.nix` | Thin profile entrypoint, identity, imports, DMS settings/session/plugin options and host conditionals. |
| `niri.nix` | niri input, navigation, workspace guards, compositor keybinds and DMS IPC actions. |
| `monitors.nix` | Host-specific output rules; `myMachine` intentionally uses runtime monitor discovery. |
| `session.nix` | User-session behavior, random DMS wallpaper selection and screenshot directory setup. |
| `themes.nix` | Stylix cursor boundary, Kora icon policy and dark desktop appearance. |
| `applications.nix` | Applications, XDG associations, NixVim and Xournal++ data synchronization. |
| `sync.nix` | Independent wallpaper/Vault synchronization services and timers. |

## DMS and visual API

The visible shell is DankMaterialShell v1.5.3, started by its official Home Manager systemd unit. niri is the sole compositor and does not embed a second shell startup command. The local `shell-conf` module exposes `programs.livara.visual` as a stable API: it installs the DMS package supplied by the host flake, writes declarative DMS settings/session JSON, installs QML plugins and registers the user Matugen hook.

DMS owns the shared wallpaper-derived theme and its native templates. The relevant DMS flags are enabled in `home/livara/home.nix` for GTK, Qt, Firefox, Zen Browser, Vesktop, Kitty, WezTerm and Neovim. The external `sync-livara-themes` adapter deliberately does not overwrite those consumer-owned files. It only materializes contracts not provided by DMS: ZenNotes, Tauon, Freesm Launcher and Xournal++.

The central flow is:

> DMS wallpaper IPC → DMS Matugen → `~/.cache/DankMaterialShell/dms-colors.json` → `livara-matugen-sync` → application-specific adapters.

The DMS native calendar remains enabled. ZenNotes tasks are an additional feature: the Python indexer reads Markdown checkboxes from the Vault, writes a JSON cache, and the Livara QML plugin exposes a bar popout and launcher provider. The plugin is installed immutably under the DMS plugin directory by Home Manager and uses only documented DMS plugin surfaces (`widget` and `launcher`).

`myMachine` hides battery and Bluetooth controls because they do not represent that hardware and keeps the Ethernet/network path. `latitude` enables battery and Bluetooth through host conditionals. The same module set is therefore reusable while the hardware-specific policy remains explicit and reviewable.

`stylix` is intentionally narrow: it provides the Bibata-Modern-Classic cursor and session variables. It is not treated as a universal application theme engine. Where an application has no supported Stylix contract, DMS Matugen or a documented native adapter is used instead.

## Input and rebuild boundaries

The XKB of niri, system locale, console keymap and keyd are separate layers. `features/keyd.nix` owns external Aitek Delta TM6101 remapping; niri owns compositor navigation and DMS actions. The modules must not redefine the same physical key in unrelated layers without an explicit host condition.

`install.sh` owns the normal workflow. It refuses to run as root, checks Git permissions and conflict state, validates or reuses hardware, runs `nix flake check --no-build --no-update-lock-file`, evaluates the selected system derivation, and invokes `nixos-rebuild` only after those gates pass. The hardware generator supports ext4 and Btrfs without formatting, repartitioning, guessing devices, or changing ACPI parameters.

## Validation

The minimum gate for a feature or host change is:

```bash
git diff --check
find scripts -maxdepth 1 -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
nix flake check --no-build --no-update-lock-file --show-trace
```

Then evaluate or build each affected host:

```bash
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
```

Declarative evaluation is necessary but not sufficient for a shell migration. On the real host, additionally validate `niri validate`, `dms doctor --json`, the DMS user service, the generated `dms-colors.json`, the random wallpaper service, cursor theme, host-specific widgets and the generated application contracts. A sandbox without a Nix executable cannot replace those hardware checks.
