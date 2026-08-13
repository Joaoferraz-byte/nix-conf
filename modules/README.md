# NixOS Module Layout

This directory contains the evaluated NixOS and flake-parts modules for the repository. The root [README](../README.md) describes the user-facing workflow, while [ARCHITECTURE.md](../ARCHITECTURE.md) records the architectural decisions and validation model.

| Path | Responsibility |
|---|---|
| `features/` | Reusable system capabilities such as Hyprland/UWSM, portals, audio, drivers, hardening, Flatpak, containers, virtualization, and development tools. |
| `packages/` | Shared package sets and compatibility definitions. |
| `hosts/` | Machine composition roots, hardware declarations, locale, identity, and host-specific policy. |
| `parts.nix` | flake-parts definitions for public module exports and shared flake metadata. |

The root `flake.nix` imports the evaluated module surface explicitly. Files under `archive/` are historical and remain outside the evaluated tree. A reusable feature must expose a stable `flake.nixosModules.<name>` or `flake.homeModules.<name>` contract at the layer where its options are evaluated.

## Adding a host

Create `modules/hosts/<host>/configuration.nix`, `default.nix`, and `hardware.nix`. The configuration module should select the features required by that machine. The host assembly should declare the corresponding `nixosConfiguration` and compose the shared desktop profile when appropriate. The hardware entrypoint should import the tracked `hardware-configuration.nix` and contain only machine-specific device, filesystem, kernel, boot, and microcode policy.

Register the host through the explicit import list in `flake.nix`, then validate its complete system derivation:

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

## Shared desktop profile

`hosts/common-desktop.nix` is a composition module. It imports Home Manager, the local Hyprland system module, the end-4 Home Manager adapter, and the NixVim module. The `home/livara/` profile is split by ownership:

| File | Owner |
|---|---|
| `session.nix` | Hyprland settings, UWSM-compatible session behavior, input, compatibility shortcuts, screenshots, idle, and wallpaper startup. |
| `themes.nix` | Matugen templates, generated output paths, GTK, Firefox, Zen Browser, ZenNotes, and browser profile adapters. |
| `applications.nix` | Applications, XDG associations, NixVim, and Xournal++ data synchronization. |
| `sync.nix` | Independent wallpaper and Vault synchronization services and timers. |
| `home.nix` | Thin profile entrypoint, identity, environment, and imports. |

## End-4 adapter

`features/end4.nix` is a Home Manager module that consumes the pinned `illogical-impulse-dotfiles` input. It links immutable QuickShell, Hyprland, Hyprlock, Fuzzel, Matugen, Wlogout, and script assets from the source tree. It also creates writable runtime directories and seeds mutable fallback files outside the Nix store.

The source profile is `ii`, exposed through `QS_CONFIG` and `$qsConfig`. QuickShell generated state belongs under `~/.local/state/quickshell/user/generated/`; it must never be replaced with a Home Manager symlink to a store path. Local overrides belong in `home/livara/session.nix` and the generated `~/.config/hypr/nix-conf.conf`, not in a copied end-4 installer tree.

## Hardware generation

For both hosts, `hardware.nix` is the tracked entrypoint and imports the tracked `hardware-configuration.nix` produced from the current machine. The common generator uses `nixos-generate-config` when possible, rejects empty or placeholder device identifiers, preserves a timestamped backup under `$XDG_STATE_HOME`, stages only the selected host hardware file, and never changes kernel ACPI parameters.

The filesystem layer supports ext4 and Btrfs. Ext4 roots preserve their device or UUID references without Btrfs options. Btrfs roots preserve the actual `subvol=` or `subvolid=` mount option for each mounted subvolume. If the official generator cannot inspect a Btrfs subvolume, the fallback uses `findmnt --kernel` and the mounted topology. It never formats, partitions, unlocks storage, guesses among ambiguous installations, or changes firmware settings.

Preview the result without modifying the repository:

```bash
cd ~/.config/nixos
./scripts/generate-hardware.sh --host latitude --dry-run
./scripts/generate-hardware.sh --host myMachine --dry-run
```

Generate and stage a selected host file:

```bash
./scripts/generate-hardware.sh --host latitude
git diff -- modules/hosts/latitude/hardware-configuration.nix
./scripts/generate-hardware.sh --host myMachine
git diff -- modules/hosts/my-machine/hardware-configuration.nix
```

From a Live ISO, mount the installed root at `/mnt`, its existing ESP at `/mnt/boot`, and use the checkout inside the installed home filesystem:

```bash
./scripts/generate-hardware.sh \
  --host latitude \
  --repo /mnt/home/livara/.config/nixos \
  --target-root /mnt
```

The generator accepts only an existing EFI System Partition, reuses an existing `/boot` mount, validates root and boot entries, checks device references, creates a timestamped backup, and stages only the selected tracked file. Do not add `acpi=`, `acpi_osi=`, `acpi=noirq`, `noapic`, or `pci=biosirq` solely to silence firmware messages.

The installer uses the existing flake lock by default. Set `NIX_CONF_UPDATE_FLAKE=1` only when an input update is intentional. A modified tracked hardware file is validated and reused instead of overwritten; set `NIX_CONF_ALLOW_HARDWARE_REPLACE=1` only for an intentional replacement. Latitude diagnostics are collected automatically only after hardware detection fails and are sanitized before upload.

## Rebuild flow

`install.sh` owns the normal workflow. It refuses to run as root, checks Git permissions and conflict state, validates or reuses hardware, runs `nix flake check --no-build --no-update-lock-file`, evaluates the selected system derivation, and invokes `nixos-rebuild` only after those gates pass. Use `NIX_CONF_REBUILD_MODE=dry-activate` or `test` before `switch` for a new shell or hardware change. On activation failure, inspect the saved log and recover with `sudo nixos-rebuild --rollback switch` if necessary.

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

The sandbox used for repository analysis does not contain a Nix executable. The Nix evaluation gate must therefore be run on the target NixOS system or another normal Nix host before applying the generation.
