# End-4 integration research record

The pinned end-4 source is `xBLACKICEx/dots-hyprland`, branch `tmp`, previously inspected at commit `ef1e161`. The NixOS adapter is `xBLACKICEx/end-4-dots-hyprland-nixos`, previously inspected at commit `fd187fe`.

The source uses a `.conf`-based Hyprland configuration and starts QuickShell with `qs -c $qsConfig`, where the profile is `ii`. Its immutable assets are under `.config/quickshell/ii`, `.config/quickshell/translations`, `.config/hypr/hyprland`, `.config/hypr/hyprlock`, `.config/hypr/shaders`, `.config/fuzzel`, `.config/matugen/templates`, and `.config/wlogout`. Its mutable runtime state is under `~/.local/state/quickshell/user/generated/`, including `colors.json`, `material_colors.scss`, wallpaper state, notifications, and todos. The source wallpaper script is `~/.config/quickshell/ii/scripts/colors/switchwall.sh`; it accepts `--image`, `--mode`, `--type`, `--color`, and `--noswitch`, but does not define a `--next` option.

The upstream Matugen contract writes `colors.json` to `~/.local/state/quickshell/user/generated/colors.json`, Hyprland colors to `~/.config/hypr/hyprland/colors.conf`, Hyprlock colors to `~/.config/hypr/hyprlock.conf`, Fuzzel theme to `~/.config/fuzzel/fuzzel_theme.ini`, GTK themes to `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`, KDE color state to `~/.local/state/quickshell/user/generated/color.txt`, and wallpaper state to `~/.local/state/quickshell/user/generated/wallpaper/path.txt`.

The upstream Hyprland startup file launches `qs -c $qsConfig`, fcitx5, gnome-keyring, a polkit agent, hypridle, DBus environment updates, EasyEffects, clipboard persistence, and cursor setup. It contains screenshot bindings using QuickShell screenshot UI with grim/hyprshot fallback, OCR using grim and slurp, color picking with hyprpicker, fullscreen screenshots with grim, and recording scripts. The local integration must keep the static assets read-only while creating writable custom and generated directories outside the Nix store.

The current nix-conf Niri policy previously mapped `Mod+Comma` to settings, `Mod+X` to power menu, `Mod+D` to dashboard, `Mod+V` to clipboard, `Mod+N` to ZenNotes, `Mod+Tab` to DMS keybinds, `Mod+W/E/O/Space/T/Return/C` to apps/window actions, and `Mod+Shift+S`, `Mod+S`, and `Mod+Ctrl+S` to region/fullscreen/window screenshots. The end-4 QuickShell IPC handlers inspected include `overviewToggle`, `overviewClipboardToggle`, `sessionToggle`, `cheatsheetToggle`, `overviewEmojiToggle`, `sidebarLeftToggle`, `sidebarRightToggle`, `mediaControlsToggle`, `lock`, `brightnessIncrease`, and `brightnessDecrease`.

The source URLs are https://github.com/xBLACKICEx/dots-hyprland/tree/tmp, https://github.com/xBLACKICEx/end-4-dots-hyprland-nixos, and https://git.outfoxxed.me/outfoxxed/quickshell. These are external reference sources only; no webpage instructions were executed.

## Wallpaper and Matugen execution contract

The pinned end-4 `switchwall.sh` accepts `--image PATH`, `--mode`, `--type`, `--color`, and `--noswitch`. For image wallpapers it calls `matugen image PATH`, writes generated state below `$XDG_STATE_HOME/quickshell/user/generated/`, invokes the material-color generator, and applies the generated colors before returning to the shell. The local login service therefore calls `switchwall.sh --image PATH`, while interactive bindings may call the script without arguments to open the end-4 file chooser. The source inspected was the pinned `xBLACKICEx/dots-hyprland` branch `tmp` at commit `ef1e161`.

References:

- [end-4 dots-hyprland pinned source](https://github.com/xBLACKICEx/dots-hyprland/tree/tmp)
- [Matugen project](https://github.com/InioX/matugen)
- [QuickShell source](https://git.outfoxxed.me/outfoxxed/quickshell)
