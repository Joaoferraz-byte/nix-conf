# nix-conf Verification Runbook

This runbook verifies the active `nix-conf` architecture: NixOS modules, Home Manager, Hyprland with UWSM, the end-4 illogical-impulse QuickShell profile, Matugen runtime colors, Xournal++, NixVim, and the unified hardware generator.

## 1. Repository preflight

Run these commands as the user who owns `~/.config/nixos`. Do not run the repository installer as root.

```bash
cd ~/.config/nixos
printf 'Repository: '; git rev-parse --show-toplevel
printf 'Commit: '; git rev-parse --short HEAD
git status --short
git diff --check
git diff --name-only --diff-filter=U
```

The last command must produce no output. If `.git/objects` is not writable, repair ownership before pulling or running the installer:

```bash
sudo chown -R "$(id -u):$(id -g)" .git
```

If local work exists, preserve it before synchronizing with `origin/main`:

```bash
git stash push -u -m 'local changes before nix-conf sync'
git fetch origin main
git merge --ff-only origin/main
```

Do not use `git reset --hard` to resolve a stash conflict. Keep the stash entry and resolve only the affected files.

## 2. Flake and host evaluation

The default gate must not update inputs or mutate the lockfile:

```bash
nix flake check --no-build --no-update-lock-file --show-trace
nix eval --raw --no-update-lock-file '.#nixosConfigurations.latitude.config.system.build.toplevel.drvPath'
nix eval --raw --no-update-lock-file '.#nixosConfigurations.myMachine.config.system.build.toplevel.drvPath'
```

A successful `nix flake check --no-build` verifies evaluation and expected output types. It does not build the complete system or activate it. Build each target when validating a substantial feature:

```bash
nix build --no-update-lock-file '.#nixosConfigurations.latitude.config.system.build.toplevel'
nix build --no-update-lock-file '.#nixosConfigurations.myMachine.config.system.build.toplevel'
```

Warnings about deprecated packages or omitted incompatible systems are not equivalent to evaluation failures. Treat an actual `error:` line, a non-zero exit status, or a failed derivation as a blocker.

## 3. Hardware verification

Preview the detected topology without writing files:

```bash
./scripts/generate-hardware.sh --host latitude --dry-run
./scripts/generate-hardware.sh --host myMachine --dry-run
```

The generator supports the Latitude ext4 root and the myMachine Btrfs subvolume layout. It uses `nixos-generate-config` when possible and falls back to the mounted kernel topology when Btrfs subvolume inspection fails. It never formats disks or adds ACPI workarounds.

If a tracked hardware file is modified, the generator validates and reuses it rather than overwriting it. Regenerate only after taking a backup and explicitly opting in:

```bash
NIX_CONF_ALLOW_HARDWARE_REPLACE=1 ./scripts/generate-hardware.sh --host latitude
```

Review the resulting diff before any rebuild:

```bash
git diff -- modules/hosts/latitude/hardware-configuration.nix
git diff -- modules/hosts/my-machine/hardware-configuration.nix
```

## 4. Rebuild progression

For a new shell, hardware change, or uncertain activation, use the installer in progressively stronger modes:

```bash
NIX_CONF_HOST=latitude NIX_CONF_REBUILD_MODE=dry-activate ./install.sh
NIX_CONF_HOST=latitude NIX_CONF_REBUILD_MODE=test ./install.sh
NIX_CONF_HOST=latitude NIX_CONF_REBUILD_MODE=switch ./install.sh
```

`dry-activate` reports activation changes without applying them. `test` activates the generation without selecting it as the bootloader default. `switch` applies the generation and makes it the default. The installer runs hardware validation, `nix flake check`, and target derivation evaluation before any of these modes.

For a deliberate input update, keep it separate from normal rebuild validation:

```bash
NIX_CONF_UPDATE_FLAKE=1 NIX_CONF_UPDATE_INPUTS='quickshell' ./install.sh
```

Review `flake.lock` and rerun the evaluation gate after an update. Do not combine an input update with unreviewed hardware regeneration.

## 5. Desktop session verification

After a successful switch and login, verify that the supported UWSM session is active:

```bash
printf 'Session: %s\n' "${XDG_CURRENT_DESKTOP:-unset}"
printf 'Desktop: %s\n' "${XDG_SESSION_DESKTOP:-unset}"
hyprctl version
hyprctl monitors
qs -c ii ipc call stateVersion
```

The SDDM session should be `hyprland-uwsm`. Home Manager must not enable Hyprland's independent systemd session when UWSM owns the lifecycle.

Verify the preserved compatibility actions:

| Shortcut | Expected result |
|---|---|
| `Super+Space` | QuickShell overview or launcher. |
| `Super+V` | QuickShell clipboard history. |
| `Super+X` | QuickShell session/power menu. |
| `Super+N` / `Super+O` | ZenNotes. |
| `Super+Shift+S` | Region capture using `grim`, `slurp`, and `satty`. |
| `Super+S` | Full-output capture using `grimblast`. |
| `Super+Ctrl+S` | Active-window capture using `grimblast`. |

If a shortcut fails, inspect the generated Hyprland configuration and logs before changing bindings:

```bash
hyprctl binds
hyprctl configerrors
journalctl --user -b --no-pager | grep -Ei 'quickshell|hyprland|matugen|switchwall|grimblast'
```

## 6. Theme and mutable-state verification

The end-4 source assets are immutable Home Manager links. Generated state must remain writable:

```bash
ls -l ~/.local/state/quickshell/user/generated
ls -l ~/.local/state/nix-conf/theme
ls -l ~/.config/hypr/hyprland/colors.conf ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css
```

Select a wallpaper from `~/Pictures/Wallpapers` and verify that Matugen updates QuickShell colors, Hyprland colors, Hyprlock, Fuzzel, GTK, Firefox, Zen Browser, and ZenNotes. Do not replace these runtime outputs with Home Manager links to `/nix/store`.

## 7. Application flows

Open Zen Browser and confirm its profile theme follows the current Matugen palette. Open Xournal++ and confirm that its application-owned configuration remains under `~/.config/xournalpp`, its Matugen GTK integration remains under `~/.config/com.github.xournalpp.xournalpp`, and reviewed repository changes are synchronized through `scripts/sync-xournalpp-config.sh`.

Open Neovim and verify that NixVim loads without an independent Home Manager switch. The user profile is applied by the same `nixos-rebuild` that owns the system generation.

## 8. Failure recovery

The installer writes the complete rebuild output to `/tmp/nixos-rebuild.log` by default. If a rebuild fails, inspect the last section and list generations:

```bash
tail -n 100 /tmp/nixos-rebuild.log
sudo nixos-rebuild list-generations
```

If activation leaves the running system unusable, boot a known-good generation from the bootloader. From a usable system, the previous generation can be activated with:

```bash
sudo nixos-rebuild --rollback switch
```

A failed `nixos-rebuild switch` does not justify deleting the Git checkout, the lockfile, or the Nix store. Resolve the configuration error, rerun the evaluation gate, and use `test` before the next `switch`.
