# end-4 Live Regression Baseline

## User-provided monitor evidence

The Latitude session reports `eDP-1` at `1920x1080`, physical size `310x170 mm`, scale `1`, and `HDMI-A-1` at `1920x1080`, physical size `530x300 mm`, scale `1`. The intended policy is a larger logical scale on the laptop panel and normal scale on the external display.

The user also reports that the taskbar icons remain low resolution, `CTRL + H/J/K/L` does not behave as the intended directional layer, and Firefox, Zen Browser, ZenNotes, GTK applications, and other consumers do not follow the end-4 dark/light palette.

## Repository findings

The local monitor module emits explicit rules for `eDP-1` at `1.25`, HDMI/DP at `1.0`, and a final wildcard fallback at `auto`. The pinned upstream `hyprland.lua` checks for `~/.config/hypr/monitors.lua` and then calls `require("monitors")`.

The Home Manager Hyprland module writes every `extraLuaFiles` entry under `~/.config/hypr/`, while `autoLoad = false` excludes the file from Home Manager's generated Lua autoload section. This is intentional for an upstream entrypoint that imports the file itself, but the live scale result proves that the complete runtime path still needs verification on the target system.

The current AppIcon patch changes `implicitSize` from `26` to `32` on `Kirigami.Icon`, enables `roundToIconSize`, and correctly does not add the unsupported `sourceSize` property. The remaining low-resolution symptom may therefore be caused by the effective QuickShell profile, a second AppIcon copy, device-pixel-ratio handling, or a stale runtime profile rather than the QML property itself.

The current keybind source builds focus bindings dynamically as `CTRL + <modifier> + <key>` and maps Brazilian-layout keycodes `10` through `19` to forwarded `F1` through `F10`. The directional failure requires checking the generated and live bind tables, modifier consumption, and whether the 60% keyboard's physical H/J/K/L keys are being interpreted as text-producing keys instead of directional dispatchers.

## External comparison

Serpantinum's current repository explicitly warns that it should not be installed on NixOS until its flake adaptation exists. Its architecture is a monolithic Arch-oriented configuration with a mutable `/etc/nixos` source link, an imperative `rsync` activation, Hyprland 0.54-style configuration, and a fixed Firefox profile path. It is useful as a visual and feature reference, but it is not a safe drop-in replacement for the existing pinned end-4 NixOS adapter.

The Serpantinum Matugen configuration demonstrates the useful breadth of a single palette transaction: QuickShell, Kitty, Discord, Firefox, website CSS, Neovim, Cava, SwayOSD, GTK, Qt5/Qt6 color state, and Hyprland outputs are all generated from one Matugen configuration. Its monitor example is not a solution for this Latitude because it fixes only `eDP-1` at scale `1.0` and does not describe the external HDMI panel.

The current Hyprland documentation states that Lua binds can use `code:<number>` for physical keycodes, and that `non_consuming` passes the key event to the active application while a bind is triggered. A directional layer should therefore use compositor dispatchers directly, avoid `send_shortcut` for arrows when possible, and consume the original H/J/K/L event so applications do not receive `CTRL + H/J/K/L` as text or editor commands. The same documentation recommends `wev` to identify the actual keycode and keysym on the installed keyboard.

The end-4 NixOS discussion confirms that generated Home Manager directories are read-only and that mutable shell state must remain outside immutable links. It recommends a module/flake boundary rather than copying the entire upstream configuration, which supports retaining the current adapter instead of replacing it with Serpantinum wholesale.

## Additional primary-source findings

The current Hyprland monitor documentation states that Lua monitor rules use `hl.monitor({ output, mode, position, scale })`, that an empty output is a fallback, that `scale = "auto"` is PPI-based, and that explicit scales must produce valid logical pixels. It also supports matching by a `desc:` output description when a port name is not stable. Source: https://wiki.hypr.land/Configuring/Basics/Monitors/.

The maintained Matugen themes repository treats browser CSS as a generated output that must be placed in the actual profile `chrome` directory, enabled with `toolkit.legacyUserProfileCustomizations.stylesheets`, and imported through absolute paths. It provides separate Firefox and Zen Browser templates and a broad set of application templates. Source: https://github.com/InioX/matugen-themes.

DankMaterialShell's application-theming documentation confirms the useful event model: Matugen outputs are regenerated on wallpaper changes and theme switches; GTK CSS is enabled by linking generated GTK files to `gtk.css`; Firefox and Zen Browser require profile-local CSS and explicit legacy stylesheet activation; and Qt applications require either GTK passthrough or a configured Qt theme backend. Source: https://danklinux.com/docs/dankmaterialshell/application-themes.

These sources support keeping Matugen as the single palette generator and improving the local post-hook, but they do not justify replacing the pinned end-4 shell with Serpantinum. Serpantinum is explicitly not NixOS-ready in its own README, while the current repository already has the correct NixOS/Home Manager boundary.

Mozilla's WebExtensions reference defines the browser content color override as the values `light`, `dark`, and `auto`, with `auto` selecting light or dark according to the browser theme. Source: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/browserSettings/overrideContentColorScheme. The local synchronizer must therefore avoid a permanent dark override and should remove or reset any stale forced-color preference when applying the shell's current mode.


External findings for the second regression review:

- Hyprland's current monitor documentation states that an empty `output` defines a fallback rule used when no other rule matches. It also documents `scale = "auto"` as PPI-based and recommends an explicit `scale = 1` fallback. Source: https://wiki.hypr.land/Configuring/Basics/Monitors/.
- Hyprland's bind documentation states that key names are the segment after `XKB_KEY_`, so `Left`, `Down`, `Up`, and `Right` are valid keysyms; keycodes use the `code:` prefix. Source: https://wiki.hypr.land/Configuring/Basics/Binds/.
- Hyprland's dispatcher documentation defines `hl.dsp.send_shortcut({ mods, key, window? })` as forwarding a specific shortcut to a window and `hl.dsp.focus({ direction })` as compositor focus movement. Source: https://wiki.hypr.land/Configuring/Basics/Dispatchers/.
- Mozilla's Firefox implementation maps `content-override` values 0 to `dark`, 1 to `light`, and all other values to `auto`; its extension setter maps `auto` to integer 2. Source: https://raw.githubusercontent.com/mozilla-firefox/firefox/main/toolkit/components/extensions/parent/ext-browserSettings.js.
- ZenNotes documentation describes its current product as a shared Electron/web application with theme families and light/dark/auto modes, but the public documentation does not expose the older local custom-theme manifest contract used by this checkout. Source: https://zennotes.org/docs and https://github.com/ZenNotes/zennotes.


ZenNotes theme-contract correction:

The current ZenNotes source confirms that a custom theme is a directory under `~/.config/zennotes/themes/<slug>/` containing `manifest.json` and `theme.css`. The manifest fields are `name`, optional `author`, `version`, `description`, `modes`, and optional `preview`; it does not require an `id` or a CSS filename field. The application derives the theme ID as `custom-<slug>`, injects only the active theme CSS, and sets `data-theme-mode="light|dark"` on the root document. Therefore the local manifest shape and `theme_id = "custom-nix-conf-matugen"` are correct, but the generated CSS must provide light tokens in `:root` and dark overrides under `:root[data-theme-mode="dark"]`, not only `color-scheme: light dark` with one `.default` palette. Sources: https://raw.githubusercontent.com/ZenNotes/zennotes/main/packages/shared-domain/src/custom-themes.ts, https://raw.githubusercontent.com/ZenNotes/zennotes/main/packages/app-core/src/lib/custom-themes.ts, and https://raw.githubusercontent.com/ZenNotes/zennotes/main/docs/explanation/custom-themes-and-community-gallery.md.


Xournal++ path:

The current official File Locations page documents the native Linux configuration folder as `~/.config/xournalpp`, containing `settings.xml`, toolbar state, metadata, and palettes. The official Toolbar Colors page also places `toolbar.ini` and `.gpl` palette files in that folder. The adapter therefore keeps `~/.config/xournalpp` as the editable out-of-store source and copies only the generated Matugen palette into the Flatpak sandbox. A legacy or sandbox-specific `~/.config/com.github.xournalpp.xournalpp` path is not used for native settings unless live evidence from the installed package requires it. Sources: https://xournalpp.github.io/guide/file-locations/ and https://xournalpp.github.io/guide/config/toolbar-colors/.
