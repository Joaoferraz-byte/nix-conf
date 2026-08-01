# Ambxst Experience Verification Runbook

This document outlines the steps to verify the fixes and new integrations implemented in the `nix-conf` and `shell-conf` repositories for the Ambxst experience.

## 1. Environment Setup

Before proceeding with the verification steps, ensure your NixOS system is updated with the latest configurations from the `nix-conf` and `shell-conf` repositories.

```bash
cd ~/nix-conf
git pull
nixos-rebuild switch --flake .#limine

cd ~/shell-conf
git pull
home-manager switch --flake .#livara
```

## 2. Verification Steps

### 2.1. Shortcuts and Window Rounding (Hyprland/axctl Integration)

**Objective**: Verify that Hyprland shortcuts are correctly recognized and window rounding is applied as expected, indicating proper `axctl` integration.

**Steps**:
1. Open a terminal (Kitty).
2. Execute `hyprctl clients` and observe the output. Look for properties related to window rounding (e.g., `rounding: 1`).
3. Test a custom shortcut defined in Ambxst (e.g., `Super + Q` to close a window, `Super + Space` to open the launcher).
4. Open multiple windows and verify that they have rounded corners.

**Expected Outcome**: All Hyprland windows should have rounded corners, and custom shortcuts should function correctly.

### 2.2. Presets (Exclusions for `general.json`)

**Objective**: Verify that `general.json` is excluded from preset operations to prevent overwriting user terminal settings.

**Steps**:
1. Open Ambxst and navigate to the Presets section.
2. Attempt to save a new preset or load an existing one.
3. After the operation, check the contents of `~/.local/share/ambxst/presets/` (or the relevant preset directory). Ensure that `general.json` is not present or modified by the preset operation.
4. Verify that your terminal settings (e.g., font, colors) remain unchanged after saving/loading presets.

**Expected Outcome**: `general.json` should not be affected by preset operations, and terminal settings should persist.

### 2.3. Kora Icons (Systemd Service and Fallback)

**Objective**: Verify that Kora icons are correctly applied across the system and within Ambxst, and that the fallback mechanism works.

**Steps**:
1. Log out and log back into your Hyprland session to ensure all environment variables are reloaded.
2. Open various applications (e.g., a file manager, web browser, terminal). Observe if Kora icons are consistently applied.
3. Open Ambxst and check if its internal icons are using the Kora theme.
4. (Optional, for fallback verification): Temporarily remove `kora-icon-theme` package from your NixOS configuration, rebuild, and observe if a default icon theme is used instead of breaking.

**Expected Outcome**: Kora icons should be consistently displayed across the system and within Ambxst. If Kora is unavailable, a graceful fallback to a default theme should occur.

### 2.4. Neovim + Kitty Integration and GitHub Dark Theme

**Objective**: Verify that Neovim launches in Kitty, clipboard integration works, and the GitHub Dark theme is correctly applied.

**Steps**:
1. Open a terminal (Kitty).
2. Type `nvim` and press Enter. Neovim should launch within the Kitty terminal.
3. Inside Neovim, copy some text (`yy`) and paste it (`p`). Then, try pasting it into another application outside Neovim (e.g., a web browser or another terminal). Verify that the clipboard content is correctly transferred.
4. Observe the color scheme within Neovim. It should display the GitHub Dark theme.
5. Test font resizing shortcuts in Kitty (`Ctrl + Plus`, `Ctrl + Minus`, `Ctrl + Backspace`).

**Expected Outcome**: Neovim should open in Kitty, clipboard operations should work seamlessly between Neovim and other applications, and the GitHub Dark theme should be visible. Font resizing in Kitty should also work.

## 3. Documentation Updates

**Objective**: Verify that all relevant documentation files (`nix-conf/docs/`, `shell-conf/docs/`) have been updated to reflect the changes.

**Steps**:
1. Navigate to the `nix-conf/docs/` and `shell-conf/docs/` directories.
2. Open and review the documentation files (e.g., `README.md`, `axctl-decision.md`, or any new files created).
3. Ensure that the documentation accurately describes the current state of the configuration, including the fixes and new integrations.

**Expected Outcome**: Documentation should be up-to-date and reflect all implemented changes.
