# NixOS Module Layout

This directory contains the evaluated NixOS and flake-parts modules for the repository. The root [README](../README.md) describes the user-facing workflow, while [ARCHITECTURE.md](../ARCHITECTURE.md) documents the architectural decisions and validation model.

| Path | Responsibility |
|---|---|
| `features/` | Reusable system capabilities such as portals, audio, drivers, firewall policy, DMS system dependencies, and Flatpak. |
| `packages/` | Shared package sets and package compatibility definitions. |
| `hosts/` | Machine composition roots, hardware declarations, locale, identity, and host-specific policy. |
| `parts.nix` | flake-parts definitions for public module exports and shared flake metadata. |

The root `flake.nix` imports the evaluated module surface explicitly. Files under `archive/` are historical and are intentionally outside the evaluated tree. A module must expose a stable `flake.nixosModules.<name>` or `flake.homeManagerModules.<name>` contract at the level where its options are evaluated.

## Adding a host

Create `modules/hosts/<host>/configuration.nix`, `default.nix`, and `hardware.nix`. The configuration module should import the features required by that machine. The host assembly should declare the corresponding `nixosConfiguration` and compose the shared desktop profile when appropriate. The hardware module should contain only machine-specific devices, filesystems, kernel modules, and boot details.

Register the host by importing its assembly from the explicit list in `flake.nix`, then validate the complete system derivation before applying it:

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

For both hosts, `hardware.nix` is the tracked entrypoint and imports the tracked `hardware-configuration.nix` produced from the current machine. The common generator uses `nixos-generate-config` when possible, rejects empty or placeholder device identifiers, preserves a timestamped backup under `$XDG_STATE_HOME`, stages only the selected host hardware file, and never changes kernel ACPI parameters. When the official generator cannot inspect a Btrfs subvolume, it reconstructs the configuration from the mounted kernel topology. Ext4 roots are emitted without Btrfs subvolume options.

Run it from the repository root on the target host:

```bash
sudo ./scripts/generate-hardware.sh --host latitude
git diff --cached -- modules/hosts/latitude/hardware-configuration.nix
sudo ./scripts/generate-hardware.sh --host myMachine
git diff --cached -- modules/hosts/my-machine/hardware-configuration.nix
git status --short
```

Do not add `acpi=`, `acpi_osi=`, `acpi=noirq`, `noapic`, or `pci=biosirq` solely to silence firmware messages. Add a kernel parameter only after correlating it with a reproducible symptom such as failed suspend, missing devices, or a verified interrupt-routing failure.

## Adding a feature

A feature must have one coherent responsibility and expose a stable NixOS or Home Manager module. Keep hardware identity and user identity out of reusable features. Keep package definitions in `packages/` when they are shared by multiple features. If a feature crosses the NixOS/Home Manager boundary, expose the boundary through a small option or a public flake output rather than reading another module's private option tree.

## Home Manager profiles

The shared desktop profile is assembled in `hosts/common-desktop.nix`. The `home/livara/` profile is split by lifecycle and ownership: `session.nix` owns DMS and Niri runtime state, `themes.nix` owns theme adapters, `applications.nix` owns applications and XDG integration, and `sync.nix` owns external repository synchronization.


## Hardware detection and recovery

The hardware entrypoints import each host's tracked `hardware-configuration.nix`. The common `generate-hardware.sh` detects the installed root from `/`, `/mnt`, `/target`, `/mnt/nixos`, or `/media/nixos`, rejects Live ISO filesystems, and requires explicit selection when multiple roots or EFI System Partitions are possible. It never formats, partitions, modifies firmware, changes ACPI parameters, or guesses between multiple installations.

Preview the detected topology without writing the repository:

```bash
sudo ./scripts/generate-hardware.sh --host latitude --dry-run
sudo ./scripts/generate-hardware.sh --host myMachine --dry-run
```

On an installed system, use the repository checkout as the working directory:

```bash
cd ~/.config/nixos
sudo ./scripts/generate-hardware.sh --host latitude
```

From a Live ISO, mount the existing Linux root at `/mnt`, mount its existing ESP at `/mnt/boot`, and use the checkout inside the installed home filesystem:

```bash
sudo ./scripts/generate-hardware.sh \
  --host latitude \
  --repo /mnt/home/livara/.config/nixos \
  --target-root /mnt
```

The generator accepts only an existing ESP with the official EFI System Partition GUID, reuses an existing `/boot` mount, and refuses ambiguous candidates. It invokes `nixos-generate-config --root` for a non-root target, validates root and `/boot` entries, rejects placeholders, checks device references, creates a timestamped backup, and stages only the selected tracked hardware file.

The filesystem layer supports `ext4` and `btrfs`. For ext4 it preserves the stable device path and emits no Btrfs options. For Btrfs it preserves the actual `subvol=` or `subvolid=` mount option for each subvolume. When the official generator cannot inspect a Btrfs subvolume, the generator uses a non-destructive fallback based on `findmnt --kernel` and the mounted topology. It does not infer an unmounted root, unlock storage, format disks, or choose between ambiguous installations.

The installer uses the existing flake lock by default; set `NIX_CONF_UPDATE_FLAKE=1` only when an input update is intentional. The sanitized diagnostic collector remains available as `scripts/collect-latitude-diagnostic.sh` and is invoked automatically only after Latitude hardware detection fails.

Review the staged result before rebuilding:

```bash
git diff --cached -- modules/hosts/latitude/hardware-configuration.nix
sudo nixos-rebuild test --flake .#latitude
```
