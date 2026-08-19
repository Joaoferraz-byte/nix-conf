{ config, lib, pkgs, inputs, desktopProfile, ... }:
let
  enabled = (desktopProfile.shellBackend or "noctalia") == "noctalia";
  homeDir = config.home.homeDirectory;
  themeRoot = "${config.xdg.stateHome}/serpantinum/theme";
  palettePath = "${config.xdg.configHome}/noctalia/palettes/Serpantinum.json";
  matugenConfig = "${config.xdg.configHome}/matugen/config.toml";
  syncApps = "${homeDir}/.local/bin/sync-serpantinum-themes";
  noctaliaBin = lib.getExe inputs.noctalia.packages.${pkgs.system}.default;

  noctaliaMatugenHook = pkgs.writeShellScript "noctalia-matugen-hook" ''
    #!/usr/bin/env bash
    set -Eeuo pipefail

    wallpaper="''${NOCTALIA_WALLPAPER_PATH:-}"
    [[ -n "$wallpaper" && -r "$wallpaper" ]] || exit 0
    [[ -r "${matugenConfig}" ]] || exit 75

    mkdir -p "${themeRoot}" "$(dirname "${palettePath}")"
    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum/logs"
    log_file="$log_dir/noctalia-matugen.log"
    mkdir -p "$log_dir"
    log() { printf '[%s] %s\n' "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)" "$*" >> "$log_file"; }

    log "generating Matugen palette from wallpaper=$wallpaper"
    "${pkgs.matugen}/bin/matugen" image "$wallpaper" --config "${matugenConfig}" --mode dark --source-color-index 0 >> "$log_file" 2>&1
    "${syncApps}" dark >> "$log_file" 2>&1

    palette_tmp="${palettePath}.tmp.$$"
    color() {
      "${pkgs.jq}/bin/jq" -r --arg key "$1" '.[$key] // "#111318"' "${themeRoot}/qs_colors.dark.json"
    }
    cat > "$palette_tmp" <<EOF
{
  "dark": {
    "mPrimary": "$(color blue)", "mOnPrimary": "$(color crust)",
    "mSecondary": "$(color green)", "mOnSecondary": "$(color crust)",
    "mTertiary": "$(color peach)", "mOnTertiary": "$(color crust)",
    "mError": "$(color red)", "mOnError": "$(color crust)",
    "mSurface": "$(color crust)", "mOnSurface": "$(color text)",
    "mSurfaceVariant": "$(color surface0)", "mOnSurfaceVariant": "$(color subtext0)",
    "mOutline": "$(color overlay0)", "mShadow": "$(color crust)",
    "mHover": "$(color surface1)", "mOnHover": "$(color text)",
    "terminal": {
      "background": "$(color crust)", "foreground": "$(color text)",
      "cursor": "$(color text)", "cursorText": "$(color crust)",
      "selectionBg": "$(color blue)", "selectionFg": "$(color crust)",
      "normal": {
        "black": "$(color crust)", "red": "$(color red)", "green": "$(color green)", "yellow": "$(color yellow)",
        "blue": "$(color blue)", "magenta": "$(color mauve)", "cyan": "$(color teal)", "white": "$(color text)"
      },
      "bright": {
        "black": "$(color overlay0)", "red": "$(color red)", "green": "$(color green)", "yellow": "$(color yellow)",
        "blue": "$(color blue)", "magenta": "$(color mauve)", "cyan": "$(color teal)", "white": "$(color text)"
      }
    }
  },
  "light": {
    "mPrimary": "$(color blue)", "mOnPrimary": "$(color crust)",
    "mSecondary": "$(color green)", "mOnSecondary": "$(color crust)",
    "mTertiary": "$(color peach)", "mOnTertiary": "$(color crust)",
    "mError": "$(color red)", "mOnError": "$(color crust)",
    "mSurface": "$(color crust)", "mOnSurface": "$(color text)",
    "mSurfaceVariant": "$(color surface0)", "mOnSurfaceVariant": "$(color subtext0)",
    "mOutline": "$(color overlay0)", "mShadow": "$(color crust)",
    "mHover": "$(color surface1)", "mOnHover": "$(color text)",
    "terminal": {
      "background": "$(color crust)", "foreground": "$(color text)",
      "cursor": "$(color text)", "cursorText": "$(color crust)",
      "selectionBg": "$(color blue)", "selectionFg": "$(color crust)",
      "normal": {
        "black": "$(color crust)", "red": "$(color red)", "green": "$(color green)", "yellow": "$(color yellow)",
        "blue": "$(color blue)", "magenta": "$(color mauve)", "cyan": "$(color teal)", "white": "$(color text)"
      },
      "bright": {
        "black": "$(color overlay0)", "red": "$(color red)", "green": "$(color green)", "yellow": "$(color yellow)",
        "blue": "$(color blue)", "magenta": "$(color mauve)", "cyan": "$(color teal)", "white": "$(color text)"
      }
    }
  }
}
EOF
    "${pkgs.jq}/bin/jq" -e '(.dark and .light) and (.dark.mPrimary and .dark.mOnPrimary and .dark.terminal.normal and .dark.terminal.bright)' "$palette_tmp" >/dev/null
    mv -f "$palette_tmp" "${palettePath}"
    "${noctaliaBin}" msg color-scheme-set custom Serpantinum >/dev/null 2>&1 || true
    log "Noctalia custom palette refreshed"
  '';


in
{
  programs.noctalia = lib.mkIf enabled {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.system}.default;
    systemd.enable = true;
    validateConfig = true;
    customPalettes = {
      Serpantinum = builtins.fromJSON (builtins.readFile ./noctalia-serpantinum-bootstrap.json);
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
        directory = "~/Wallpapers";
        directory_dark = "~/Wallpapers";
        directory_light = "~/Wallpapers";
        automation.enabled = false;
      };
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "Serpantinum";
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
        started = "${noctaliaBin} msg wallpaper-random";
        wallpaper_changed = noctaliaMatugenHook;
        colors_changed = "${syncApps} dark";
      };
    };
  };

}
