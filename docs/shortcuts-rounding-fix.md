# DMS Keybinds and Window Rounding Configuration

This document details the configuration of DMS keybinds and window rounding settings in the Niri compositor.

## Overview

DMS (DankMaterialShell) manages keybinds at runtime through its daemon service. Niri provides the compositor layer and handles window decoration settings such as rounding and gaps.

## Keybinds Management

DMS keybinds are registered at runtime via the DMS daemon. The keybinds configuration is handled by the `CompositorKeybinds.qml` service, which communicates with the DMS daemon to apply keybinds.

### Core DMS Shortcuts

| Key | Action | Command |
|-----|--------|---------|
| `Super` | Launcher | `dms run launcher` |
| `Super + D` | Dashboard | `dms run dashboard` |
| `Super + A` | Assistant | `dms run assistant` |
| `Super + V` | Clipboard | `dms run clipboard` |
| `Super + .` | Emoji | `dms run emoji` |
| `Super + N` | Notes | `dms run notes` |
| `Super + T` | Tmux | `dms run tmux` |
| `Super + ,` | Wallpapers | `dms run wallpapers` |
| `Super + Shift + C` | Settings | `dms run config` |
| `Super + Tab` | Overview | `dms run overview` |
| `Super + Esc` | Power Menu | `dms run powermenu` |
| `Super + S` | Tools | `dms run tools` |
| `Super + Shift + S` | Screenshot | `dms run screenshot` |
| `Super + Shift + R` | Screen Record | `dms run screenrecord` |
| `Super + Shift + A` | Lens | `dms run lens` |
| `Super + Alt + B` | Reload Shell | `dms reload` |

### Window Navigation Shortcuts (Niri)

- `Super + 1-9`: Switch to workspace
- `Super + Shift + 1-9`: Move window to workspace
- `Super + Left/Right/Up/Down`: Focus window
- `Super + Shift + Left/Right/Up/Down`: Move window
- `Super + C`: Close window
- `Super + W`: Open Zen Browser
- `Super + E`: Open File Manager
- `Super + O`: Open ZenNotes
- `Super + Space`: Toggle Spotlight
- `Super + T`: Open Terminal
- `Super + Return`: Open Terminal

### Hardware Keys (Media/Volume/Brightness)

- `XF86AudioRaiseVolume`: Increase volume via `wpctl`
- `XF86AudioLowerVolume`: Decrease volume via `wpctl`
- `XF86AudioMute`: Mute/unmute via `wpctl`
- `XF86MonBrightnessUp`: Increase brightness
- `XF86MonBrightnessDown`: Decrease brightness
- `XF86AudioPlay`: Play/pause media via `playerctl`
- `XF86AudioNext`: Next track via `playerctl`
- `XF86AudioPrev`: Previous track via `playerctl`

## Window Decoration Settings

Window rounding and gaps are configured in `modules/features/niri.nix`:

- **Rounding**: 12.0 pixels (applied to all window corners)
- **Gaps**: 5 pixels (inner gaps between windows)
- **Border**: Disabled
- **Focus Ring**: Disabled

These settings are applied automatically when Niri starts.

## Configuration Files

- **DMS Keybinds**: `shell-conf/modules/services/CompositorKeybinds.qml`
- **Niri Settings**: `shell-conf/modules/niri.nix`
- **DMS Configuration**: `shell-conf/modules/dms.nix`

## Applying Changes

To apply keybinds or decoration changes:

```bash
cd ~/.config/nixos
git pull origin main
sudo nixos-rebuild switch --flake .#myMachine
```

After the rebuild, DMS will register keybinds at runtime, and Niri will apply window decoration settings immediately.

## Troubleshooting

If keybinds are not working:

1. Check that DMS daemon is running: `systemctl --user status dms`
2. Verify keybinds configuration: `cat ~/.config/DankMaterialShell/keybinds.json`
3. Check Niri logs: `journalctl --user -u niri -n 50`

If window rounding is not applied:

1. Verify Niri is running: `pgrep niri`
2. Check Niri configuration: `cat ~/.config/niri/config.kdl`
3. Reload Niri: `niri msg action load-config-file`
