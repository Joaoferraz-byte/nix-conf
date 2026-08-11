# Deprecated Feature Modules

These modules were previously available as `self.nixosModules.<name>` but are no
longer imported by any host configuration. They are kept here for historical
reference only. Do NOT import from this directory.

| Module | Previously provided | Status |
|---|---|---|
| ambxst.nix | Ambxst desktop shell | Superseded by Caelestia/DMS |
| caelestia-shell.nix | Caelestia Shell | Superseded by DMS + Niri |
| dank-material-shell.nix | DMS NixOS module | Superseded by shell-conf + dms-system |
| noctalia.nix | Noctalia desktop | Superseded by DMS |
| nvf.nix | Nvf editor | Superseded by vim-conf (NixVim) |
| shell.nix | Shell utilities | Superseded by shell-conf |

Removed: 2026-08-09
