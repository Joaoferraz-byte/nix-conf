# nix-conf

## Overview

Declarative NixOS configuration based on flakes for desktop and laptop. Niri compositor + DankMaterialShell (DMS) via the `shell-conf` flake.

| Area | Location | Responsibility |
|---|---|---|
| Flake and pinned inputs | `flake.nix`, `flake.lock` | Defines hosts and pins all transitive dependencies. |
| Hosts | `modules/hosts/` | Declares hardware, hostname, and machine-specific choices. |
| System features | `modules/features/` | Encapsulates desktop, portals, audio, greeter, and other services. |
| Packages | `modules/packages/` | Declares Nix and Flatpak packages. |
| Shell (DMS + Niri) | `inputs.shell-conf` | DankMaterialShell + Niri via separate flake. |
| Neovim (NixVim) | `inputs.vim-conf` | Declarative IDE with dynamic DMS theme. |

## Shell

DankMaterialShell + Niri is provided by the `shell-conf` flake:

| Input | Responsibility |
|---|---|
| `dms.homeModules.dank-material-shell` | DMS settings (themes, widgets, plugins) |
| `dms.homeModules.niri` | niri + DMS integration (preset keybinds, spawn) |

The `dms.homeModules.niri` internally imports `niri-flake`, avoiding `programs.niri` option conflicts.

## DMS Plugins

Plugins declared via `dms-plugin-registry`:

| Plugin | Description |
|---|---|
| `quickCapture` | Screen capture with annotation and OCR |
| `screenCapture` | Screenshot via Niri (area, fullscreen, active window) |
| `dankQuickSearch` | Fast web search via engine prefixes |

## Screenshot Keybinds (via shell-conf)

| Shortcut | Action |
|---|---|
| Super+Shift+S | Selected region screenshot |
| Super+S | Fullscreen screenshot |
| Super+Ctrl+S | Active window screenshot |

## Deployment

```bash
sudo nixos-rebuild switch --flake .#myMachine
sudo nixos-rebuild switch --flake .#latitude
```

## Updates

```bash
nix flake update
nix flake check
nix build --dry-run --no-link .#nixosConfigurations.myMachine.config.system.build.toplevel
```

## References

- [DankMaterialShell](https://danklinux.com/docs/dankmaterialshell/nixos-flake)
- [Niri-flake](https://github.com/sodiboo/niri-flake)
- [DMS Plugin Registry](https://github.com/AvengeMedia/dms-plugin-registry)
- [shell-conf](https://github.com/Joaoferraz-byte/shell-conf)
- [vim-conf](https://github.com/Joaoferraz-byte/vim-conf)
