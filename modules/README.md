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

For the Latitude host, `hardware.nix` is the tracked entrypoint and imports the tracked `hardware-configuration.nix` produced from the current machine. The generator uses `nixos-generate-config --show-hardware-config`, rejects empty or placeholder device identifiers, preserves a timestamped backup under `$XDG_STATE_HOME`, stages only the generated hardware file, and never changes kernel ACPI parameters. It falls back to `/etc/nixos/hardware-configuration.nix` only when live generation is unavailable or fails.

Run it from the repository root after booting the target Latitude:

```bash
./scripts/generate-latitude-hardware.sh
git diff --cached -- modules/hosts/latitude/hardware-configuration.nix
git status --short
```

Do not add `acpi=`, `acpi_osi=`, `acpi=noirq`, `noapic`, or `pci=biosirq` solely to silence firmware messages. Add a kernel parameter only after correlating it with a reproducible symptom such as failed suspend, missing devices, or a verified interrupt-routing failure.

## Adding a feature

A feature must have one coherent responsibility and expose a stable NixOS or Home Manager module. Keep hardware identity and user identity out of reusable features. Keep package definitions in `packages/` when they are shared by multiple features. If a feature crosses the NixOS/Home Manager boundary, expose the boundary through a small option or a public flake output rather than reading another module's private option tree.

## Home Manager profiles

The shared desktop profile is assembled in `hosts/common-desktop.nix`. The `home/livara/` profile is split by lifecycle and ownership: `session.nix` owns DMS and Niri runtime state, `themes.nix` owns theme adapters, `applications.nix` owns applications and XDG integration, and `sync.nix` owns external repository synchronization.


## Latitude hardware recovery

The Latitude hardware entrypoint imports `modules/hosts/latitude/hardware-configuration.nix`. The generated file must be produced on the target machine or from a Live ISO. The adaptive recovery scripts detect the installed root from `/`, `/mnt`, `/target`, `/mnt/nixos`, or `/media/nixos`, reject Live ISO filesystems, and require explicit selection when multiple roots or EFI System Partitions are possible. They never format, partition, modify firmware, change ACPI parameters, or guess between multiple installations.

Preview the detected topology without mounting anything:

```bash
sudo ./scripts/recover-latitude-boot.sh --repo "$PWD" --dry-run
```

On an installed system or emergency shell, run without a target argument; `/` is selected only when it is a mounted non-temporary filesystem containing NixOS files:

```bash
sudo ./scripts/recover-latitude-boot.sh --repo "$PWD"
```

From a Live ISO, mount the existing Linux root read-write at `/mnt`, but do not format or repartition it. The helper can autodetect `/mnt`; if the layout is ambiguous, select both values explicitly:

```bash
sudo ./scripts/recover-latitude-boot.sh \
  --repo /mnt/home/livara/.config/nixos \
  --target-root /mnt \
  --esp /dev/disk/by-partuuid/REAL-ESP-PARTUUID
```

The helper lists block devices with explicit `lsblk` columns, waits for udev, accepts an ESP only when its partition type is the official EFI System Partition GUID, refuses to guess when there is no candidate or more than one candidate, and invokes `nixos-generate-config` with `--root` only for a non-root target. The generator validates root and `/boot` entries, rejects placeholder identifiers, checks device references, creates a timestamped backup, and stages only the tracked hardware file.

When the official generator reports `Failed to retrieve subvolume info` for Btrfs, the generator uses a non-destructive fallback. It reads `TARGET`, `SOURCE`, `FSTYPE`, and `OPTIONS` from the kernel mount table, preserves the actual Btrfs `subvol=` option, resolves stable `/dev/disk/by-*` paths when available, and writes one valid hardware module. It does not infer an unmounted root, unlock storage, format disks, or choose between ambiguous installations.

`nixos-facter` can provide richer hardware facts in a future extension, but it does not choose an existing installation disk; Disko is deliberately excluded from this recovery path because it can change disk layouts.

If the helper reports multiple or no ESP candidates, inspect the printed inventory and mount the correct existing partition manually. Do not use `mkfs`, `parted`, `fdisk`, `wipefs`, `acpi=noirq`, `noapic`, or `pci=biosirq` as a workaround.

For a non-destructive report without modifying the repository configuration, run:

```bash
sudo LATITUDE_REPORT_DIR=/tmp/latitude-diagnostics \
  ./scripts/collect-latitude-hardware-report.sh
```

The installer uses the existing flake lock by default; set `NIX_CONF_UPDATE_FLAKE=1` only when an input update is intentional.

Review the staged result before rebuilding:

```bash
git diff --cached -- modules/hosts/latitude/hardware-configuration.nix
sudo nixos-rebuild test --flake .#latitude
```
