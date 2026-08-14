# End-4 architecture review research

## External findings

The official end-4 NixOS discussion emphasizes that Home Manager-managed configuration directories are read-only and that the mutable parts of the shell must remain outside immutable store links. A robust NixOS integration should therefore pin the upstream source, manage static inputs declaratively, and seed or synchronize explicitly writable runtime state rather than copying the complete upstream `.config` tree imperatively.[1]

The `xBLACKICEx/end-4-dots-hyprland-nixos` project demonstrates the useful boundary of a Home Manager module: expose the shell as a module, install the required package set, and keep Hyprland and portal configuration in the NixOS layer.[2] This is a valid integration pattern, but it does not remove the need for local state ownership decisions because the upstream shell includes generated and user-edited files.

The Matugen themes project documents that Firefox-based browser CSS must be written to the actual profile `chrome` directory and imported using an absolute path. A theme template alone does not activate browser customization; the browser preference `toolkit.legacyUserProfileCustomizations.stylesheets` must also be enabled, and `userChrome.css` must import the generated file.[3]

## Architectural implication

The current adapter follows the right broad model by pinning end-4, wrapping QuickShell with QML modules, and separating static source files from writable state. Its main weakness is that application adapters are only partially authoritative: GTK files are generated, but browser profile preferences, ZenNotes theme schema, and application reload hooks are not handled as one coherent theme transaction. The review should consolidate these into a single Matugen post-hook that generates the palette, installs profile-local links, updates activation preferences, and reloads only consumers that support safe runtime reload.

[1]: https://github.com/end-4/dots-hyprland/discussions/1093
[2]: https://github.com/xBLACKICEx/end-4-dots-hyprland-nixos
[3]: https://github.com/InioX/matugen-themes


The current Hyprland documentation confirms that Lua is the preferred configuration format from Hyprland 0.55 onward. The official example uses full direction names (`left`, `right`, `up`, `down`) for focus dispatchers and exposes monitor configuration through `hl.monitor({ output, mode, position, scale })`.[4] The bind API supports explicit flags such as `release`, `non_consuming`, `ignore_mods`, and `description`; custom bindings should use the documented API and then be verified with `hyprctl binds` on the running session.[5]

Architecturally, the current adapter's use of abbreviated focus directions (`l`, `d`, `u`, `r`) is not aligned with the current upstream example and should be replaced with full direction names. For function-key emulation, `send_shortcut` is an appropriate compositor dispatcher only if the installed Hyprland revision implements it correctly; the generated bind list and a real-session test are required because recent discussions report release-event issues in some versions.[6]

[4]: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
[5]: https://wiki.hypr.land/Configuring/Basics/Binds/
[6]: https://github.com/hyprwm/Hyprland/discussions/14554


Zen Browser's official live-editing guide confirms that `userChrome.css` is read from the actual profile `chrome` directory and requires `toolkit.legacyUserProfileCustomizations.stylesheets=true`; Flatpak profiles live under `~/.var/app/app.zen_browser.zen/.zen`.[7] The official Matugen Zen template uses the `.default` color family, including `surface_container`, `on_background`, and `on_primary`, rather than assuming a dark-only variant.[8] The current `themes.nix` template uses `.dark` for every target and omits the browser preference, which explains why the browser layer is not reliably active and why it cannot follow a light/dark shell mode.

ZenNotes documentation describes themes and overrides as plain files under the user's configuration, so the generated CSS should be treated as a runtime output and linked into the selected theme directory, while the manifest and activation preference remain declarative.[9]

[7]: https://docs.zen-browser.app/guides/live-editing
[8]: https://github.com/InioX/matugen-themes/blob/main/templates/zen-userchrome.css
[9]: https://zennotes.org/docs


The pinned end-4 entrypoint loads `hyprland.lib`, services, environment, execs, general, rules, colors, keybinds, optional custom modules, optional `monitors.lua`, and finally shell overrides. This provides a clean ownership boundary: monitor policy belongs in a local `monitors.lua` override, while shell UI behavior remains in the upstream profile.[10]

The pinned upstream Matugen configuration generates QuickShell colors, Hyprland colors, Hyprlock, Fuzzel, GTK 3, GTK 4, KDE color state, and wallpaper state. Its official GTK template and `colors.json` use `.default` palette values and semantic Material 3 surfaces such as `surface_container`, `surface_container_lowest`, and `on_surface`, rather than hard-coded dark variants.[11] [12] [13]

[10]: https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/hypr/hyprland.lua
[11]: https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/matugen/config.toml
[12]: https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/matugen/templates/gtk-3.0/gtk.css
[13]: https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/matugen/templates/colors.json


## Additional external findings

The current Hyprland wiki documents `focus({ direction })` with the short values `l`, `r`, `u`, and `d`, and documents `send_shortcut({ mods, key, window? })`. Therefore the existing short direction values are valid; a non-working bind must also be checked through the generated bind table and the live session, not changed solely because the upstream example uses full words.[14]

The current Hyprland monitor contract is `hl.monitor({ output, mode, position, scale })`. The official example uses a fallback monitor rule with `mode = "preferred"`, `position = "auto"`, and `scale = "auto"`; the documentation explains that `auto` lets Hyprland choose a scale based on monitor pixel density and that explicit scales must produce valid logical pixels.[15]

The official Matugen GTK template uses semantic `.default` colors such as `background.default`, `surface_container.default`, and `on_surface.default`. The maintained Matugen Zen Browser template also uses the `.default` family and requires the actual profile `chrome/userChrome.css` path plus the browser stylesheet preference.[16] [17]

The current ZenNotes documentation describes theme families and automatic light/dark modes, while the repository docs confirm that themes are installed as a manifest plus a CSS file under the user's themes directory. A local adapter should therefore advertise both modes and update only the generated CSS and selected theme identifier, leaving user-editable application state outside immutable Home Manager links.[18]

The sandbox does not provide the `hyprland`, `hyprctl`, or `uwsm` binaries and is not running a Wayland session (`XDG_SESSION_TYPE` and `WAYLAND_DISPLAY` are unset), so it can validate Nix and generated Lua but cannot perform a real compositor test here. A live-session verification must be performed on the Latitude after rebuild using `hyprctl binds`, `hyprctl monitors -j`, and the QuickShell IPC.[19]

[14]: https://wiki.hypr.land/Configuring/Basics/Dispatchers/
[15]: https://wiki.hypr.land/Configuring/Basics/Monitors/
[16]: https://raw.githubusercontent.com/end-4/dots-hyprland/69f1a543196d47286a4630c2c0868a1827e512f2/dots/.config/matugen/templates/gtk-3.0/gtk.css
[17]: https://raw.githubusercontent.com/InioX/matugen-themes/main/templates/zen-userchrome.css
[18]: https://zennotes.org/docs
[19]: https://wiki.hypr.land/Configuring/Basics/Binds/


## Consolidated implementation findings

- The pinned Hyprland documentation accepts the short focus directions `l`, `r`, `u`, and `d`; changing them to full words alone would not explain a failed bind. The generated bind table and the live session must be checked. The implementation will keep the documented short direction values unless a live test proves otherwise.
- The pinned end-4 entrypoint loads `monitors.lua` from the Hyprland root. The host-specific module must therefore materialize that exact path, not `custom/monitors.lua`.
- The sandbox has no `hyprland`, `hyprctl`, `uwsm`, Wayland display, or compositor session. Static Nix/Lua validation is possible here, but the final behavioral check must run on the Latitude.

## Consolidated architecture findings

- Hyprland's official Lua examples use short focus directions (`l`, `r`, `u`, `d`) in the end-4 pin; local navigation should match that contract and use the upstream modifier order (`CTRL + SUPER + ...`) for consistency.
- The upstream end-4 `switchwall.sh` receives `--mode light|dark`, updates GNOME `color-scheme` and `gtk-theme`, invokes Matugen, applies generated colors, and then runs `post_process`. Application synchronization belongs after that event rather than in a second palette generator.
- Matugen documents `.default` as the mode-aware color family for templates; separate `.light`/`.dark` output is not required for the active-mode pipeline. CSS consumers must be regenerated after the end-4 mode/wallpaper event.
- ZenNotes custom themes use a `custom-<slug>` theme ID and the `[appearance]` TOML keys `theme_family = "custom"`, `theme_mode = "auto"`, and `theme_id = "custom-<slug>"`; the renderer applies `data-theme-mode` and accepts RGB triplets for the `--z-*` variables. Sources: https://github.com/ZenNotes/zennotes and https://github.com/InioX/matugen/wiki/Configuration.
- Hyprland monitor rules accept explicit scale values or `auto`; the host-specific output rules must be registered in the root `~/.config/hypr/monitors.lua`, before any fallback wildcard, because the end-4 entrypoint imports that file directly. Source: https://wiki.hypr.land/Configuring/Basics/Monitors/.
- Hyprland `send_shortcut` is the native dispatcher for forwarding a key with an explicit modifier set. Source: https://wiki.hypr.land/Configuring/Basics/Binds/ and https://wiki.hypr.land/Configuring/Basics/Dispatchers/.

ZenNotes' official `apps/desktop/src/main/app-config.ts` maps the portable appearance preferences to the `[appearance]` TOML section with snake_case keys: `theme_family`, `theme_mode`, and `theme_id`. The custom theme ID is resolved as `custom-<slug>`. Source: https://github.com/ZenNotes/zennotes/blob/main/apps/desktop/src/main/app-config.ts.
