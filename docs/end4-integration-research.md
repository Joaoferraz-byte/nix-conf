# End-4 integration research record

The active source is the official `end-4/dots-hyprland` repository, pinned as the non-flake input `illogical-impulse-dotfiles` at immutable revision `69f1a543196d47286a4630c2c0868a1827e512f2`. The previous integration used the third-party `xBLACKICEx/dots-hyprland` `tmp` branch, whose legacy `.conf` fragments were incompatible with the current Home Manager and Hyprland Lua path. The official revision was selected because it contains the current `hyprland.lua` entrypoint, native Lua modules, the `ii` QuickShell profile, and the current Matugen template layout.

## Configuration contract

The end-4 Hyprland entrypoint requires the following modules in the user configuration directory:

```text
~/.config/hypr/hyprland.lua
~/.config/hypr/hyprland/env.lua
~/.config/hypr/hyprland/execs.lua
~/.config/hypr/hyprland/general.lua
~/.config/hypr/hyprland/keybinds.lua
~/.config/hypr/hyprland/lib/init.lua
~/.config/hypr/hyprland/rules.lua
~/.config/hypr/hyprland/services/init.lua
~/.config/hypr/hyprland/variables.lua
~/.config/hypr/hyprland/shellOverrides/main.lua
```

The Home Manager adapter sets `wayland.windowManager.hyprland.configType = "lua"`, places the official entrypoint in `extraConfig`, adds the Hyprland module directories to Lua's `package.path`, and installs static modules through `extraLuaFiles` with `autoLoad = false`. This is intentional: the upstream entrypoint controls module order and conditionally loads custom modules. Importing legacy `.conf` fragments into the generated Lua file is not supported.

Runtime-writable files are seeded as ordinary files rather than symlinks to the Nix store. This applies to `hyprland/colors.lua`, `hyprland/shellOverrides/main.lua`, `hyprlock.conf`, `hyprlock/colors.conf`, GTK CSS files, and Fuzzel's generated theme. The QuickShell source tree is static; its generated data and user configuration are stored under `~/.config/illogical-impulse` and `$XDG_STATE_HOME/quickshell/user/generated/`.

## QuickShell profile and packages

The selected profile is `ii`, launched with `qs -c ii`. The adapter does not run the upstream installer and does not copy the entire user `.config` tree. It imports the upstream profile into a Nix derivation for static assets, keeps runtime state outside the store, and supplies the Python environment required by the color-generation scripts. The local login service selects a wallpaper only when a supported image exists under `~/Pictures/Wallpapers` and invokes the upstream-compatible `switchwall.sh --image PATH` interface.

The current upstream profile does not declare a Hyprland plugin requirement. Therefore the NixOS composition does not run `hyprpm` and does not list a plugin that cannot be resolved declaratively. The previous “failed to load plugins” message came from the incompatible legacy configuration path, not from a required end-4 plugin that this adapter omitted.

## Theme and icons

Matugen now follows the current template contract:

| Output | Writable runtime path |
|---|---|
| Material color JSON | `$XDG_STATE_HOME/quickshell/user/generated/colors.json` |
| Hyprland Lua colors | `~/.config/hypr/hyprland/colors.lua` |
| Hyprlock colors | `~/.config/hypr/hyprlock/colors.conf` |
| Fuzzel colors | `~/.config/fuzzel/fuzzel_theme.ini` |
| GTK 3 colors | `~/.config/gtk-3.0/gtk.css` |
| GTK 4 colors | `~/.config/gtk-4.0/gtk.css` |
| KDE color state | `$XDG_STATE_HOME/quickshell/user/generated/color.txt` |
| Wallpaper path state | `$XDG_STATE_HOME/quickshell/user/generated/wallpaper/path.txt` |
| Firefox, Zen Browser, and ZenNotes | `$XDG_STATE_HOME/nix-conf/theme/` |

The icon theme is explicitly `pkgs.kora-icon-theme` with GTK icon name `Kora`. `Bibata-Modern-Classic` remains the cursor theme. This is separate from the Matugen color palette and prevents an accidental replacement of Kora with an upstream default icon set.

## Preserved local behavior

The custom Lua bindings preserve the prior workflow: QuickShell settings, overview, session menu, clipboard history, ZenNotes, terminal, Nautilus, Zen Browser, window close, directional focus, fullscreen state, screenshots, color picking, and wallpaper switching. Screenshots continue to use `grim`, `grimblast`, `slurp`, and `satty`. Recording uses a local `gpu-screen-recorder` wrapper because the previous `wf-recorder` package is incompatible with the selected FFmpeg API. The wrapper supports region, active-monitor, audio, start, and SIGINT-stop flows.

## References

1. [Official end-4 source at the pinned revision](https://github.com/end-4/dots-hyprland/commit/69f1a543196d47286a4630c2c0868a1827e512f2)
2. [Official Hyprland Lua entrypoint](https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/hypr/hyprland.lua)
3. [Official Matugen configuration](https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/matugen/config.toml)
4. [Home Manager Hyprland module](https://raw.githubusercontent.com/nix-community/home-manager/master/modules/services/window-managers/hyprland/default.nix)
5. [Home Manager Hyprland Lua renderer](https://raw.githubusercontent.com/nix-community/home-manager/master/modules/services/window-managers/hyprland/lib.nix)
6. [Matugen project](https://github.com/InioX/matugen)
7. [QuickShell source](https://git.outfoxxed.me/outfoxxed/quickshell)

## Serpantinum decision

Serpantinum was evaluated as a possible visual and architectural replacement. It is not adopted as a direct input. Its current tree is a personal NixOS configuration rather than a reusable flake module: it imports Home Manager through a channel path, contains host-specific hardware and user paths, assumes `/etc/nixos/config`, combines session services that are not part of this host contract, and uses a hyprlang `.conf` tree with imperative `rsync --update` activation scripts. Its README also warns that the NixOS installation path is not ready for general use.

That design would reintroduce the exact class of problems already corrected: a legacy `.conf` tree mixed with the current Hyprland Lua contract, mutable files copied from a machine-specific path, and configuration ownership split between Nix and imperative activation. Serpantinum may still be used as visual inspiration, but no code is imported until individual assets are rewritten and reviewed for licensing and compatibility.

## Applying settings edited by the interface

The end-4 settings interface edits runtime state, primarily `~/.config/illogical-impulse/config.json`, and may create user custom files under `~/.config/hypr/custom/` or `~/.config/hypr/hyprland/shellOverrides/`. These paths are intentionally outside the Nix store. Home Manager must seed them only when absent; it must not overwrite them on every activation.

The supported workflow is:

```bash
cd ~/.config/nixos
./scripts/sync-end4-state.sh status
./scripts/sync-end4-state.sh export
git diff -- home/livara/end4-state
# Review the result, then commit and push it deliberately.
```

To apply a reviewed state on another activation or host, use:

```bash
cd ~/.config/nixos
./scripts/sync-end4-state.sh import
hyprctl reload
qs -c ii ipc call reloadGlobal
```

The import command creates a timestamped backup under `$XDG_STATE_HOME/nix-conf/backups/end4-state/`. Generated Matugen outputs and QuickShell caches are not exported because they are derived data. The repository-managed state is therefore an explicit user decision, while ordinary `nixos-rebuild` remains reproducible and does not silently capture mutable runtime changes.

The command is also installed as `~/.local/bin/sync-end4-state` by Home Manager. Running it from the checkout is preferred because it guarantees that export and import operate on the intended `~/.config/nixos` repository rather than `/etc/nixos`.

## Autogenerated warning diagnosis

Hyprland 0.55 and newer use `~/.config/hypr/hyprland.lua` and display an autogenerated warning when the file contains `hl.config({ autogenerated = true })`. The current Home Manager Lua renderer does not insert that marker. The activation hook therefore backs up and removes a regular user file only when it contains the marker or legacy hyprlang syntax; it does not remove a valid Lua configuration or a Home Manager symlink. If the warning remains after activation, inspect the active file with:

```bash
readlink -f ~/.config/hypr/hyprland.lua
sed -n '1,30p' ~/.config/hypr/hyprland.lua
systemctl --user status home-manager-livara.service --no-pager
```

A plain example generated by Hyprland should be backed up and removed only after the new Home Manager generation has been activated. The expected active contract is Lua, not `hyprland.conf`.
