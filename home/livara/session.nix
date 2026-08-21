{ config, inputs, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;
  visualCfg = config.programs.livara.visual;
  randomDmsWallpaper = pkgs.writeShellApplication {
    name = "dms-wallpaper-random-on-login";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      inputs.dms.packages.${pkgs.system}.default
    ];
    text = ''
      set -Eeuo pipefail
      wallpapers_dir="${home}/Wallpapers"
      wallpaper="$(find "$wallpapers_dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -print0 | shuf -z -n 1 | xargs -0 -r printf '%s')"
      [[ -n "$wallpaper" ]] || {
        printf '%s\n' "No wallpaper found in $wallpapers_dir" >&2
        exit 1
      }
      for attempt in {1..120}; do
        # `version` is not a DMS IPC target in v1.5.3. The documented
        # wallpaper call itself is the readiness probe and the only owner of
        # wallpaper/Matugen state. DMS starts asynchronously after niri, so
        # keep the one-shot alive long enough for Quickshell to publish IPC.
        if dms ipc call wallpaper set "$wallpaper" >/dev/null 2>&1; then
          printf '%s\n' "Selected random wallpaper after $attempt attempt(s): $wallpaper"
          exit 0
        fi
        if (( attempt % 15 == 0 )); then
          printf '%s\n' "Waiting for DMS wallpaper IPC (attempt $attempt/120)" >&2
        fi
        sleep 1
      done
      printf '%s\n' "DMS IPC was not ready after 120 attempts" >&2
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

  systemd.user.services.dms-wallpaper-random-on-login = lib.mkIf visualCfg.wallpaperAutomationEnabled {
    Unit = {
      Description = "Select one random DMS wallpaper at graphical session start";
      After = [ "dms.service" ];
      Wants = [ "dms.service" ];
      PartOf = [ "niri.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${randomDmsWallpaper}/bin/dms-wallpaper-random-on-login";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 180;
    };
    # niri does not activate graphical-session.target; bind the one-shot to
    # the compositor session just like the DMS service itself.
    Install.WantedBy = [ "niri.service" ];
  };

  systemd.user.services.dankcalendar = {
    Unit = {
      Description = "DankCalendar daemon for the DMS native calendar backend";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.flatpak}/bin/flatpak run com.danklinux.dankcalendar run --session --hidden";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/Pictures/Screenshots"
  '';
}
