# Verification Runbook: Ambxst System Fixes

This document provides the exact sequence of commands to apply and verify the fixes for Ambxst on the host **limine**.

## Prerequisites

- Ensure you have pulled the latest changes in `~/nix-conf` and `~/shell-conf`.
- You must have sudo privileges for the rebuild.

## Step 1: System Rebuild

The host "limine" is configured under the `myMachine` flake output in `nix-conf`.

```bash
cd ~/nix-conf
git pull origin main
sudo nixos-rebuild switch --flake .#myMachine
```

*Reasoning: `modules/hosts/my-machine/configuration.nix` explicitly sets `networking.hostName = "limine"`.*

## Step 2: Service Initialization

Restart the Ambxst user service to ensure it picks up the new environment and binary paths.

```bash
systemctl --user restart ambxst.service
```

## Step 3: Journalctl Verification

Check the logs for any remaining permission or PATH errors.

```bash
journalctl --user -u ambxst.service --no-pager -n 100
```

**Success Criteria:**
- No "Permission denied" errors for `.json` files in `~/.local/state/ambxst/config/`.
- No "find: ~/.config/nixos/Wallpapers: No such file or directory" errors.
- No "binary could not be found" warnings for `axctl`, `hyprctl`, `brightnessctl`, etc.

## Step 4: Axctl Daemon Verification

Confirm that the `axctl` daemon is running and ready.

```bash
# Check if the process is running
pgrep -f "axctl.*daemon"

# Check if the IPC socket is active
ls -la /tmp/axctl.sock 2>/dev/null || echo "Socket not found"
```

**Success Criteria:** `axctl daemon` process is alive and the socket exists.

## Step 5: Runtime Functional Tests

### 1. Shortcuts
Test the following shortcuts (registered via Ambxst):
- `SUPER + Enter`: Should launch Kitty terminal.
- `SUPER + D`: Should launch the Dashboard.
- `SUPER + R`: Should restart the `ambxst.service` (custom bind in `hyprland.nix`).
- `SUPER + ,`: Should open the Wallpapers picker.

### 2. Dashboard Widgets
Open the Dashboard (`SUPER + D`) and verify:
- **Network/Bluetooth**: Icons should show live status, not placeholders.
- **Preset Selection**: Select a different preset (e.g., "Ambxst Default"). It should load without "Permission denied" errors in the logs.
- **Rounding**: Go to Theme > Compositor and change the Rounding value. Window corners should update **immediately**.

### 3. Icons
Verify that app icons (e.g., in the taskbar or app launcher) use the **Kora** theme instead of falling back to Phosphor icons.

### 4. Brightness
Test the brightness slider in the bar:
- Drag the slider; the screen brightness should change.
- Run `ambxst brightness +10` in the terminal and verify the slider updates to match.

## Troubleshooting

If any check fails, refer to the following diagnostic notes:

- **Permission Denied**: Check `ls -la ~/.local/state/ambxst/config/`. The directory should be owned by `livara`. If not, run `sudo chown -R livara:users ~/.local/state/ambxst`.
- **Missing Wallpapers**: Check `ls -la ~/.config/nixos/Wallpapers`. It should be a symlink to `~/nix-conf/Wallpapers`.
- **Icons still Phosphor**: Check `echo $XDG_DATA_DIRS`. It must include `/home/livara/.nix-profile/share`.
- **Rounding not live**: Ensure `hyprctl` is in the PATH of the `ambxst.service`.
