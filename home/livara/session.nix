{ config, inputs, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;
  randomDmsWallpaper = pkgs.writeShellApplication {
    name = "livara-dms-wallpaper-random-on-login";
    runtimeInputs = [ inputs.dms.packages.${pkgs.system}.default pkgs.coreutils pkgs.findutils ];
    text = ''
      set -Eeuo pipefail
      wallpapers_dir="${home}/Wallpapers"
      wallpaper="$(find "$wallpapers_dir" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -print 2>/dev/null | shuf -n 1)"
      [[ -n "$wallpaper" ]] || exit 0
      for _ in $(seq 1 30); do
        if dms ipc call wallpaper set "$wallpaper"; then
          exit 0
        fi
        sleep 1
      done
      exit 1
    '';
  };

in
{
  # hypridle is used only as a compositor-independent idle/lock daemon. niri
  # remains the sole compositor and owns monitor power actions.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "niri msg action power-on-monitors";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "niri msg action power-off-monitors";
          on-resume = "niri msg action power-on-monitors";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend || loginctl suspend";
        }
      ];
    };
  };

  systemd.user.services.livara-dms-wallpaper-random-on-login = {
    Unit = {
      Description = "Select a random Livara wallpaper through the DMS IPC after login";
      After = [ "graphical-session.target" "dms.service" ];
      Wants = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
      ConditionPathIsDirectory = "${home}/Wallpapers";
    };
    Service = {
      Type = "oneshot";
      TimeoutStartSec = 45;
      ExecStart = "${randomDmsWallpaper}/bin/livara-dms-wallpaper-random-on-login";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/Pictures/Screenshots"
  '';
}
