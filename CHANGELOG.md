# Changelog

## Migration to Serpantinum (2026-08-14)

The active desktop shell now uses the Serpantinum QuickShell profile on Hyprland with the NixOS UWSM integration. The `shell-conf` adapter publishes the reviewed source tree and Home Manager module. Matugen owns wallpaper-derived colors for QuickShell, Hyprland, GTK, Qt, terminals, Neovim, Firefox, Zen Browser and ZenNotes.

The Latitude-specific hardware scripts were replaced by one adaptive generator that supports ext4 and Btrfs for both hosts. The installer now validates hardware before rebuilding, propagates the original failure code, and uses the repository checkout at `~/.config/nixos`.

## Retired shell experiment: DankMaterialShell (2026-08-06)

Historical record of an intermediate shell experiment. It is no longer part of the active composition.

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
