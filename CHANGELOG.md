# Changelog

## Migration to DankMaterialShell (2026-08-06)

The Ambxst-X shell has been replaced by DankMaterialShell (DMS) + Niri compositor. Integration is done via the `shell-conf` flake.

### Removed
- References to Ambxst, axctl, and Hyprland Lua

## Organization Refactor
- `system-hardening` module added to `configuration.nix`.

## Fixes and Improvements (2026-08-05)

### SDDM Cursor
- Removed `XCURSOR_THEME` and `XCURSOR_SIZE` variables from `greeter.nix` (redundant with SDDM theme).

### Host Latitude — input.helium
- Removed `inputs.helium.overlays.default` (reference to non-existent input). `gnome-icon-theme` overlay also removed.

### Host Latitude — Duplicate Configuration
- Removed duplicate `services.xserver.xkb` and `services.tlp` blocks.

### Zen Browser Double Declaration
- Removed direct package `inputs.zen-browser.packages."${pkgs.system}".default` and manual desktop entry. Now uses `inputs.zen-browser.homeModules.beta` with `programs.zen-browser.enable`.

### Vault Sync
- Added `home.activation.cloneVault` to clone the repository on first activation. Added `.gitignore` in Vault to exclude `plugins/`, `themes/`, and `_attachments/`.

### WezTerm
- Removed close confirmation for shells (`zsh`, `bash`, `fish`, `nu`).

### CHANGELOG
- Removed reference to Helium Browser (replaced by Zen Browser).
