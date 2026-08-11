# Architecture

Declarative NixOS system with Niri, DankMaterialShell (DMS), and Java/C++ development environment. Managed by flake-parts with import-tree for modules.

## File Structure

```
├── flake.nix                  # Flake entry point
├── flake.lock                 # Dependency pinning
├── ARCHITECTURE.md            # This file
├── CHANGELOG.md               # Change history
├── README.md                  # General overview
├── home/livara/home.nix       # User Home Manager config
└── modules/
    ├── README.md              # Module conventions
    ├── parts.nix              # Systems supported and composition
    ├── features/              # Feature modules
    ├── hosts/                 # Machine-specific configurations
    ├── packages/              # Package declarations
    └── homeManagerModules.nix # Re-exported HM modules
```

## NixOS Modules

| Module | Responsibility |
|---|---|
| `corePackages` | Essential CLI and system tools |
| `nvidia` | NVIDIA proprietary drivers and settings |
| `greeter` | SDDM with custom theme |
| `desktop-portals` | XDG portals for Wayland |
| `flatpak` | Flatpak support and remotes |
| `audiorelay` | AudioRelay service |
| `keyd` | Keyboard remapping |
| `system-hardening` | Firewall, sudo, auto GC, zram |

## Shell Integration

`shell-conf` is a separate flake that packages DankMaterialShell and Niri with integration:

| Module | Responsibility |
|---|---|
| `dms.homeModules.dank-material-shell` | DMS settings (themes, widgets, plugins) |
| `dms.homeModules.niri` | niri + DMS integration (preset keybinds, auto spawn) |

Internally, `dms.homeModules.niri` already imports the `niri-flake` home-manager module, avoiding `programs.niri` option conflicts.

## Neovim Integration

`vim-conf` is a separate flake that packages the NixVim configuration with a dynamic DMS theme:

| Module | Responsibility |
|---|---|
| `nixvim.legacyPackages` | Neovim package build |

## Hosts

| Host | Description | Kernel | GPU |
|---|---|---|---|
| `myMachine` | Main Desktop | Zen | NVIDIA |
| `latitude` | Dell Laptop | Stable | Intel |

Both share the same shell configuration (shell-conf) and home-manager (home.nix).
