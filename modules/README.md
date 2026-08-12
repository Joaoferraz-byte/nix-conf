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

## Adding a feature

A feature must have one coherent responsibility and expose a stable NixOS or Home Manager module. Keep hardware identity and user identity out of reusable features. Keep package definitions in `packages/` when they are shared by multiple features. If a feature crosses the NixOS/Home Manager boundary, expose the boundary through a small option or a public flake output rather than reading another module's private option tree.

## Home Manager profiles

The shared desktop profile is assembled in `hosts/common-desktop.nix`. The `home/livara/` profile is split by lifecycle and ownership: `session.nix` owns DMS and Niri runtime state, `themes.nix` owns theme adapters, `applications.nix` owns applications and XDG integration, and `sync.nix` owns external repository synchronization.
