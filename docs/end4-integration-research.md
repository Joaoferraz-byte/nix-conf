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
