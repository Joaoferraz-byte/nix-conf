{ config, inputs, lib, pkgs, ... }:

let
  visual = config.programs.livara.visual;
  homeDir = config.home.homeDirectory;
  themeRoot = "${config.xdg.stateHome}/livara/theme";
  palettePath = "${config.xdg.configHome}/noctalia/palettes/Livara.json";
  matugenConfig = "${config.xdg.configHome}/matugen/config.toml";
  matugenSync = "${config.home.profileDirectory}/bin/livara-matugen-sync";
  syncThemes = "${config.home.profileDirectory}/bin/sync-livara-themes";
  noctaliaPackage = inputs.noctalia.packages.${pkgs.system}.default;
  noctaliaBin = lib.getExe noctaliaPackage;

  noctaliaMatugenHook = pkgs.writeShellScript "noctalia-livara-matugen-hook" ''
    set -Eeuo pipefail
    wallpaper="''${NOCTALIA_WALLPAPER_PATH:-}"
    [[ -n "$wallpaper" && -r "$wallpaper" ]] || exit 0
    [[ -x "${matugenSync}" && -r "${matugenConfig}" ]] || exit 75

    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/livara/logs"
    mkdir -p "$log_dir" "$(dirname "${palettePath}")"
    log_file="$log_dir/noctalia-matugen.log"
    log() { printf '[%s] %s\n' "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)" "$*" >> "$log_file"; }

    log "generating Matugen palette from wallpaper=$wallpaper"
    NOCTALIA_WALLPAPER_PATH="$wallpaper" "${matugenSync}" >> "$log_file" 2>&1

    color() {
      "${pkgs.jq}/bin/jq" -r --arg key "$1" '.[$key] // "#111318"' "${themeRoot}/palette.dark.json"
    }

    palette_tmp="${palettePath}.tmp.$$"
    cat > "$palette_tmp" <<EOF
{
  "dark": {
    "mPrimary": "$(color primary)", "mOnPrimary": "$(color on_primary)",
    "mSecondary": "$(color secondary)", "mOnSecondary": "$(color on_secondary)",
    "mTertiary": "$(color tertiary)", "mOnTertiary": "$(color on_tertiary)",
    "mError": "$(color error)", "mOnError": "$(color on_error)",
    "mSurface": "$(color base)", "mOnSurface": "$(color text)",
    "mSurfaceVariant": "$(color surface0)", "mOnSurfaceVariant": "$(color subtext0)",
    "mOutline": "$(color overlay0)", "mShadow": "$(color crust)",
    "mHover": "$(color surface1)", "mOnHover": "$(color text)",
    "terminal": {
      "background": "$(color crust)", "foreground": "$(color text)",
      "cursor": "$(color text)", "cursorText": "$(color crust)",
      "selectionBg": "$(color primary)", "selectionFg": "$(color on_primary)",
      "normal": {
        "black": "$(color crust)", "red": "$(color error)", "green": "$(color secondary)", "yellow": "$(color yellow)",
        "blue": "$(color primary)", "magenta": "$(color tertiary)", "cyan": "$(color teal)", "white": "$(color text)"
      },
      "bright": {
        "black": "$(color overlay0)", "red": "$(color error)", "green": "$(color secondary)", "yellow": "$(color yellow)",
        "blue": "$(color primary)", "magenta": "$(color tertiary)", "cyan": "$(color teal)", "white": "$(color text)"
      }
    }
  },
  "light": {
    "mPrimary": "$(color primary)", "mOnPrimary": "$(color on_primary)",
    "mSecondary": "$(color secondary)", "mOnSecondary": "$(color on_secondary)",
    "mTertiary": "$(color tertiary)", "mOnTertiary": "$(color on_tertiary)",
    "mError": "$(color error)", "mOnError": "$(color on_error)",
    "mSurface": "$(color base)", "mOnSurface": "$(color text)",
    "mSurfaceVariant": "$(color surface0)", "mOnSurfaceVariant": "$(color subtext0)",
    "mOutline": "$(color overlay0)", "mShadow": "$(color crust)",
    "mHover": "$(color surface1)", "mOnHover": "$(color text)",
    "terminal": {
      "background": "$(color crust)", "foreground": "$(color text)",
      "cursor": "$(color text)", "cursorText": "$(color crust)",
      "selectionBg": "$(color primary)", "selectionFg": "$(color on_primary)",
      "normal": {
        "black": "$(color crust)", "red": "$(color error)", "green": "$(color secondary)", "yellow": "$(color yellow)",
        "blue": "$(color primary)", "magenta": "$(color tertiary)", "cyan": "$(color teal)", "white": "$(color text)"
      },
      "bright": {
        "black": "$(color overlay0)", "red": "$(color error)", "green": "$(color secondary)", "yellow": "$(color yellow)",
        "blue": "$(color primary)", "magenta": "$(color tertiary)", "cyan": "$(color teal)", "white": "$(color text)"
      }
    }
  }
}
EOF
    "${pkgs.jq}/bin/jq" -e '(.dark and .light) and (.dark.mPrimary and .dark.mOnPrimary and .dark.terminal.normal and .dark.terminal.bright)' "$palette_tmp" >/dev/null
    mv -f "$palette_tmp" "${palettePath}"
    "${noctaliaBin}" msg color-scheme-set custom Livara >/dev/null 2>&1 || true
    "${syncThemes}" dark >> "$log_file" 2>&1
    log "Noctalia custom palette and application adapters refreshed"
  '';

in
{
  config = lib.mkIf visual.enable {
    programs.noctalia = {
      enable = true;
      package = noctaliaPackage;
      # niri owns the compositor session startup; start Noctalia from the
      # compositor's documented spawn-at-startup entry instead of creating a
      # competing graphical-session systemd launcher.
      systemd.enable = false;
      validateConfig = true;
      customPalettes = {
        Livara = builtins.fromJSON (builtins.readFile ./noctalia-livara-bootstrap.json);
      };
      settings = {
        shell = {
          telemetry_enabled = false;
          niri_overview_type_to_launch_enabled = false;
          clipboard_enabled = true;
        };
        shell.panel = {
          transparency_mode = "glass";
          borders = true;
          shadow = true;
          launcher_placement = "floating";
          control_center_placement = "attached";
          wallpaper_placement = "attached";
        };
        shell.launcher = {
          show_icons = true;
          show_app_origin_indicator = false;
          sort_by_usage = true;
          provider_prefix = "/";
        };
        wallpaper = {
          enabled = true;
          fill_mode = "crop";
          transition = [ "fade" "wipe" "zoom" ];
          transition_duration = 900;
          transition_on_startup = false;
          directory = visual.wallpaperDirectory;
          directory_dark = visual.wallpaperDirectory;
          directory_light = visual.wallpaperDirectory;
          # Pick a wallpaper at shell startup when no persisted default exists.
          # The directory is synchronized by wallpapers-sync before the next
          # periodic run, and Noctalia owns the actual wallpaper application.
          automation = {
            enabled = true;
            interval_seconds = 86400;
            order = "random";
            recursive = true;
          };
        };
        theme = {
          mode = "dark";
          source = "custom";
          custom_palette = "Livara";
          pure_black_dark = false;
        };
        backdrop = {
          enabled = true;
          blur_intensity = 0.35;
          tint_intensity = 0.25;
        };
        notification = {
          enable_daemon = true;
          layer = "top";
          background_opacity = 0.97;
        };
        bar.main = {
          position = "top";
          thickness = 34;
          background_opacity = 0.92;
          radius = 12;
          margin_edge = 10;
          padding = 14;
          widget_spacing = 6;
          shadow = true;
          reserve_space = true;
          start = [ "launcher" "wallpaper" "workspaces" ];
          center = [ "clock" ];
          end = [ "media" "tray" "notifications" "clipboard" "network" "bluetooth" "volume" "brightness" "battery" "control-center" "session" ];
        };
        dock.enabled = false;
        desktop_widgets.enabled = false;
        hooks = {
          wallpaper_changed = noctaliaMatugenHook;
          colors_changed = "${syncThemes} dark";
        };
      };
    };
  };
}
