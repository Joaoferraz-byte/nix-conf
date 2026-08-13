# Historical runtime-state permission issue

This document records a permission failure from the retired Ambxst shell. Ambxst, DMS, and the old `shell-conf` integration are not part of the active composition. The current shell is end-4 QuickShell on Hyprland with UWSM.

## Historical symptom

The old shell attempted to write files such as:

```text
/home/livara/.local/state/ambxst/config/dock.json
```

and failed when the directory was absent or owned by `root`. The old service started before its configuration directory was guaranteed to exist, which made the error appear intermittently after a rebuild.

## Current state ownership

The active end-4 adapter uses the following ownership model:

| Path | Owner | Mutability |
|---|---|---|
| `~/.config/quickshell/ii` | Home Manager and the pinned end-4 source | Immutable source link |
| `~/.config/hypr/hyprland/*.conf` | Home Manager plus local overrides | Source fragments are immutable; local generated files are writable where required |
| `~/.local/state/quickshell/user/generated` | QuickShell and Matugen | Writable runtime state |
| `~/.local/state/nix-conf/theme` | Matugen and browser/theme adapters | Writable generated theme state |
| `~/Pictures/Wallpapers` | User | Writable wallpaper input |

Do not recreate `~/.local/state/ambxst`, add an `ambxst.service`, or restore a shell-conf symlink to solve a current QuickShell issue. Those actions would reintroduce a retired owner and could cause two shells to compete for the same session resources.

## Current diagnostic procedure

Check ownership and links as the logged-in user:

```bash
find ~/.local/state/quickshell ~/.local/state/nix-conf/theme -maxdepth 3 -printf '%M %u:%g %p\n' 2>/dev/null
ls -ld ~/.config/quickshell/ii ~/.config/hypr
journalctl --user -b --no-pager | grep -Ei 'quickshell|matugen|switchwall|permission denied'
```

If a runtime directory is owned by `root`, repair only the user-owned state directory:

```bash
sudo chown -R "$(id -u):$(id -g)" ~/.local/state/quickshell ~/.local/state/nix-conf ~/.config/quickshell ~/.config/hypr
```

Do not run `home-manager`, the end-4 scripts, or `install.sh` through `sudo`. The installer refuses to run as root because root-owned files in the user checkout or Home Manager profile are a common source of later failures.

For a configuration change, use the repository workflow:

```bash
cd ~/.config/nixos
NIX_CONF_REBUILD_MODE=dry-activate ./install.sh
NIX_CONF_REBUILD_MODE=test ./install.sh
./install.sh
```

The writable-state rule is the same as for the old issue, but the active paths and owner have changed: QuickShell and Matugen own their generated state, while Nix owns the immutable source assets.
