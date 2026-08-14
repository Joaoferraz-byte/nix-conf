# Hyprland and end-4 shortcut reference

This document describes the active shortcut and window-decoration contract for the Hyprland session managed by UWSM and the end-4 QuickShell profile.

## Ownership

Hyprland owns compositor keybinds, focus, workspaces, window movement, fullscreen state, rounding, gaps and input settings. QuickShell owns shell surfaces such as the overview, clipboard history, session menu, cheatsheet and sidebars. The two layers communicate through QuickShell IPC calls such as `qs -c ii ipc call overviewToggle`.

The source dotfile is pinned as the non-flake `illogical-impulse-dotfiles` input. Local compatibility bindings are declared in `modules/features/end4.nix` as the `custom/keybinds.lua` module; they do not modify the source checkout and are shared by both hosts. The local module must not redeclare a binding already supplied by `hyprland/keybinds.lua`.

## Upstream shell and application shortcuts

| Key | Action | Owner |
| --- | --- | --- |
| `Super + Tab` | Toggle workspace overview | Upstream end-4 QuickShell |
| `Super + V` | Toggle clipboard history | Upstream end-4 QuickShell |
| `Super + N` | Toggle the right sidebar | Upstream end-4 QuickShell |
| `Super + O` | Toggle the left sidebar | Upstream end-4 QuickShell |
| `Super + Slash` | Toggle the cheatsheet | Upstream end-4 QuickShell |
| `Ctrl + Alt + Delete` | Toggle the session menu | Upstream end-4 QuickShell |
| `Super + Return` or `Super + T` | Launch the first available terminal | Upstream end-4 launcher chain |
| `Super + E` | Launch the first available file manager | Upstream end-4 launcher chain |
| `Super + W` | Launch the first available browser | Upstream end-4 launcher chain |
| `Super + C` | Launch the first available code editor | Upstream end-4 launcher chain |
| `Super + Q` | Close the active window | Upstream Hyprland binding |

The local adapter intentionally does not duplicate these bindings. This prevents one key press from launching two applications or from replacing an upstream action such as the sidebar, scratchpad or code editor.

## Local shortcuts

| Key | Action | Implementation |
| --- | --- | --- |
| `Super + Space` | Toggle the overview surface | `qs -c ii ipc call overviewToggle` |
| `Super + Comma` | Open end-4 QuickShell settings | `qs -p ~/.config/quickshell/ii/settings.qml` |
| `Super + Alt + X` | Toggle the session menu | `qs -c ii ipc call sessionToggle` |
| `Super + Z` | Open ZenNotes | `zennotes` |
| `Super + Alt + W` | Open Zen Browser beta | `zen-beta` |
| `Super + Shift + W` | Select a wallpaper | end-4 `switchwall.sh` |
| `Super + Ctrl + Shift + W` | Select a wallpaper | end-4 `switchwall.sh` |

## Window navigation and the 60% keyboard layer

`Super + Left/Right/Up/Down` focuses a neighboring window. The local 60% layer provides the same focus operation without requiring arrow keys: `Super + Ctrl + H/J/K/L` focuses left/down/up/right respectively. `Super + Shift + Left/Right/Up/Down` remains the upstream window-movement layer. `Super + Ctrl + H/J/K/L` is intentionally reserved for focus and does not duplicate the upstream move bindings.

The function-key layer maps `Ctrl + 1` through `Ctrl + 9` to `F1` through `F9`, and `Ctrl + 0` to `F10`, using Hyprland's native `send_shortcut` dispatcher with an empty modifier set. `Super + D` toggles maximized state and `Super + F` toggles fullscreen. `Super + 1-9` and `Super + 0` select workspaces 1-10. Hyprland and the upstream end-4 scripts provide additional workspace movement and scratchpad bindings.

The active decoration contract is defined in the imported end-4 `general.lua` and `rules.lua` modules. Local changes belong in the Lua override module or a future host-specific override rather than in the source input.

## Screenshots and visual tools

| Key | Action | Owner |
| --- | --- | --- |
| `Print` | Copy the full output | Upstream end-4 screenshot fallback |
| `Ctrl + Print` | Copy and save the full output | Upstream end-4 screenshot fallback |
| `Super + Shift + S` | Select and annotate a region | Upstream QuickShell surface with fallback |
| `Super + Shift + C` | Pick a color and copy it | Upstream end-4 color picker |
| `Super + Shift + R` | Record a region | Upstream end-4 recording surface |

The NixOS adapter replaces the unavailable `wf-recorder` path with `gpu-screen-recorder`, while preserving the end-4 recording entry points.

## Hardware keys

Volume and mute keys use `wpctl`. Brightness keys use the end-4 QuickShell brightness IPC with `brightnessctl` fallback. Media keys use `playerctl` for play/pause, previous and next actions. The keyboard layout is `br`, and the touchpad uses tap-to-click, disable-while-typing and natural scrolling.

## Applying changes

Run the following from the repository checkout:

```bash
cd ~/.config/nixos
git pull --ff-only origin main
NIX_CONF_HOST=latitude ./install.sh
```

For the other host, use `NIX_CONF_HOST=myMachine ./install.sh`. The installer runs the Nix evaluation gate before switching the system and does not attempt a rebuild when hardware generation fails.

## Troubleshooting

Check the compositor, UWSM session and process ownership with:

```bash
systemctl --user status graphical-session.target --no-pager
systemctl --user status hypridle.service --no-pager
pgrep -a Hyprland
pgrep -a 'qs|quickshell'
qs -c ii ipc call TEST_ALIVE
```

Inspect detailed activation and session logs with:

```bash
journalctl --user -b --no-pager -o short-precise | grep -Ei 'home-manager|activation|hyprland|uwsm|quickshell|qml|hypridle'
journalctl --user -u home-manager-livara.service -b -e --no-pager
find "/run/user/$UID/quickshell" -type f -name 'log.qslog' -print -exec tail -n 200 {} \;
hyprctl configerrors
hyprctl binds
```

If `qs -c ii ipc call TEST_ALIVE` fails, restart the shell in the foreground to expose QML errors:

```bash
pkill -x qs || true
qs -c ii
```

The official end-4 configuration file is `~/.config/illogical-impulse/config.json`. The adapter creates `{}` only when the file is absent, so the QuickShell `JsonAdapter` can materialize its defaults without overwriting user preferences. The `rounded-polygon-qmljs` Git submodule is fetched explicitly and the adapter adds its required `qmldir` declaration for QuickShell 0.3. [1] [2] [3]

If a generated palette is stale, run the end-4 wallpaper switcher after confirming that the wallpaper path exists:

```bash
~/.config/quickshell/ii/scripts/colors/switchwall.sh
```

Matugen outputs are intentionally stored under `~/.local/state/quickshell/user/generated/` and `~/.local/state/nix-conf/theme/`. They must remain writable and must not be replaced by symlinks into the Nix store.

## References

[1]: https://ii.clsty.link/en/ii-qs/03config/ "illogical-impulse configuration documentation"
[2]: https://github.com/end-4/dots-hyprland/issues/1407 "end-4 QuickShell config.json reload issue"
[3]: https://ii.clsty.link/en/ii-qs/04troubleshooting/ "illogical-impulse troubleshooting and submodule guidance"
