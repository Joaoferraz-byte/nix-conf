{ config, lib, compositor ? "hyprland", ... }:
let
  home = config.home.homeDirectory;
in
{
  # Hyprland is enabled by the NixOS module with UWSM. Home Manager only
  # owns user services and files, avoiding a second compositor lifecycle.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = if compositor == "niri" then "niri msg action power-on-monitors" else "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = if compositor == "niri" then "niri msg action power-off-monitors" else "hyprctl dispatch dpms off";
          on-resume = if compositor == "niri" then "niri msg action power-on-monitors" else "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend || loginctl suspend";
        }
      ];
    };
  };

  home.activation.migrateLegacyHyprlandConf = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    stale="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$stale" ] && [ ! -L "$stale" ]; then
      backup="$HOME/.local/state/nix-conf/backups/hyprland.conf.legacy.$(date +%Y%m%d%H%M%S)"
      $DRY_RUN_CMD mkdir -p "$(dirname "$backup")"
      $DRY_RUN_CMD cp -a "$stale" "$backup"
      $DRY_RUN_CMD rm -f "$stale"
    fi
    if [ -L "$stale" ]; then
      $DRY_RUN_CMD rm -f "$stale"
    fi
  '';

  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/Pictures/Screenshots"
  '';
}
