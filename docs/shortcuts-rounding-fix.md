# Hyprland and end-4 shortcut reference

This document describes the active shortcut and window-decoration contract for the Hyprland session managed by UWSM and the end-4 QuickShell profile.

## Ownership

Hyprland owns compositor keybinds, focus, workspaces, window movement, fullscreen state, rounding, gaps and input settings. QuickShell owns shell surfaces such as the overview, clipboard history, session menu, cheatsheet and sidebars. The two layers communicate through QuickShell IPC calls such as `qs -c ii ipc call overviewToggle`.

The source dotfile is pinned as the non-flake `illogical-impulse-dotfiles` input. Local compatibility bindings are declared in `modules/features/end4.nix` as the `custom/keybinds.lua` module; they do not modify the source checkout and are shared by both hosts.

## Shell and application shortcuts

| Key | Action | Implementation |
| --- | --- | --- |
| `Super + Space` | Toggle overview and launcher | `qs -c ii ipc call overviewToggle` |
| `Super + D` | Toggle overview | `qs -c ii ipc call overviewToggle` |
| `Super + V` | Clipboard history | `qs -c ii ipc call overviewClipboardToggle` |
| `Super + N` | Open ZenNotes | `zennotes` |
| `Super + Tab` | Toggle end-4 cheatsheet | `qs -c ii ipc call cheatsheetToggle` |
| `Super + X` | Toggle session menu | `qs -c ii ipc call sessionToggle` |
| `Super + W` | Open Zen Browser beta | `zen-beta` |
| `Super + E` | Open Nautilus | `nautilus` |
| `Super + O` | Open ZenNotes | `zennotes` |
| `Super + T` or `Super + Return` | Open WezTerm | `wezterm` |
| `Super + C` | Close the active window | Lua `hl.dsp.window.close()` |

The upstream end-4 bindings remain active for its overview, sidebars, media controls, brightness controls, wallpaper switching and fallback launchers. Local bindings are deliberately limited to historical nix-conf shortcuts that would otherwise collide with the imported configuration.

## Window navigation and workspaces

`Super + Left/Right/Up/Down` focuses a neighboring window. `Super + F` toggles fullscreen and `Super + Shift + F` toggles the maximized window state. `Super + 1-9` and `Super + 0` select workspaces 1-10. Hyprland and the upstream end-4 scripts provide additional workspace movement and scratchpad bindings.

The active decoration contract is defined in the imported end-4 `general.lua` and `rules.lua` modules. Local changes belong in the Lua override module or a future host-specific override rather than in the source input.

## Screenshots and visual tools

| Key | Action | Command |
| --- | --- | --- |
| `Print` | Copy the full output | `grimblast --notify copy output` |
| `Ctrl + Print` | Copy and save the full output | `grimblast --notify copysave output` |
| `Super + Shift + S` | Select a region and annotate it with Satty | `grim`, `slurp` and `satty` |
| `Super + S` | Copy the active output | `grimblast --notify copy output` |
| `Super + Ctrl + S` | Copy the active window | `grimblast --notify copy active` |
| `Super + Shift + C` | Pick a color and copy it | `hyprpicker -a` |

The imported end-4 configuration also provides its QuickShell screenshot surface, recording scripts and OCR fallback. The local region shortcut remains available for the existing Satty workflow.

## Hardware keys

Volume and mute keys use `wpctl`. Brightness keys use the end-4 QuickShell brightness IPC with `brightnessctl` fallback. Media keys use `playerctl` for play/pause, previous and next actions. The keyboard layout is `br`, and the touchpad uses tap-to-click, disable-while-typing and natural scrolling.

## Applying changes

Run the following from the repository checkout:

```bash
cd ~/.config/nixos
./install.sh
```

For an explicit host selection, use `NIX_CONF_HOST=latitude ./install.sh` or `NIX_CONF_HOST=myMachine ./install.sh`. The installer runs `nix flake check --no-build` before switching the system and does not attempt a rebuild when hardware generation fails.

## Troubleshooting

Check the compositor and UWSM session with:

```bash
systemctl --user status graphical-session.target
systemctl --user status hypridle.service
pgrep -a Hyprland
pgrep -a qs
```

Check QuickShell and Hyprland logs with:

```bash
journalctl --user -b --no-pager | grep -Ei 'quickshell|hyprland|uwsm|hypridle'
qs -c ii ipc call TEST_ALIVE
hyprctl reload
```

If a generated palette is stale, run the end-4 wallpaper switcher after confirming that the wallpaper path exists:

```bash
~/.config/quickshell/ii/scripts/colors/switchwall.sh
```

Matugen outputs are intentionally stored under `~/.local/state/quickshell/user/generated/` and `~/.local/state/nix-conf/theme/`. They must remain writable and must not be replaced by symlinks into the Nix store.
