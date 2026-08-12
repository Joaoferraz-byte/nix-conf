{ config, pkgs, lib, inputs, self, ... }:
let
  randomDmsWallpaper = pkgs.writeShellScript "dms-wallpaper-random-on-login" ''
    set -eu
    wallpapers_dir="${config.home.homeDirectory}/Wallpapers"
    wallpaper="$(${pkgs.findutils}/bin/find "$wallpapers_dir" -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
      -print | ${pkgs.coreutils}/bin/shuf -n 1)"
    if [ -z "$wallpaper" ]; then
      exit 1
    fi
    for attempt in $(${pkgs.coreutils}/bin/seq 1 30); do
      if dms ipc call wallpaper set "$wallpaper"; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    exit 1
  '';
in
{
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "br";
      touchpad = {
        tap = true;
        dwt = true;
        natural-scroll = true;
      };
    };
    spawn-at-startup = [
      { command = [ "xwayland-satellite" ":0" ]; }
    ];
  };

  home.activation.reloadNiriConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if command -v niri >/dev/null 2>&1 && [ -n "''${NIRI_SOCKET:-}" ]; then
      niri msg action load-config-file >/dev/null 2>&1 || true
    fi
  '';

  home.activation.migrateDmsSession = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    OLD_SESSION="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
    if [ -f "$OLD_SESSION" ] && [ ! -L "$OLD_SESSION" ]; then
      BACKUP="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json.legacy"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -f "$OLD_SESSION" "$BACKUP"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$OLD_SESSION"
    fi
  '';

  xdg.stateFile."DankMaterialShell/session.json".force = true;

  programs.dank-material-shell = {
    plugins.wallpaperCarousel = {
      enable = true;
      settings.wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    };
    session = {
      perMonitorWallpaper = false;
      perModeWallpaper = false;
      wallpaperCyclingEnabled = false;
      wallpaperTransition = "random";
      isLightMode = false;
      doNotDisturb = false;
      doNotDisturbUntil = 0;
      nightModeEnabled = false;
      nightModeTemperature = 4500;
      nightModeHighTemperature = 6500;
      nightModeAutoEnabled = false;
      nightModeAutoMode = "time";
      nightModeStartHour = 18;
      nightModeStartMinute = 0;
      nightModeEndHour = 6;
      nightModeEndMinute = 0;
      themeModeAutoEnabled = false;
      themeModeAutoMode = "time";
      themeModeStartHour = 18;
      themeModeStartMinute = 0;
      themeModeEndHour = 6;
      themeModeEndMinute = 0;
      themeModeShareGammaSettings = true;
      latitude = -23.599722;
      longitude = -46.791389;
      nightModeUseIPLocation = false;
      nightModeLocationProvider = "";
      weatherLocation = "Jardim João XXIII, São Paulo, SP, Brasil";
      weatherCoordinates = "-23.599722,-46.791389";
      weatherHourlyDetailed = true;
      showThirdPartyPlugins = false;
      pluginBrowserInstalledFirst = false;
      pluginBrowserSortMode = "default";
      launchPrefix = "";
      searchAppActions = true;
      locale = "pt_BR";
      timeLocale = "pt_BR";
      appOverrides."zen-beta".name = "Zen Browser";
    };
  };

  systemd.user.services.dms-wallpaper-random-on-login = {
    Unit = {
      Description = "Select one random DMS wallpaper at graphical session start";
      After = [ "dms.service" "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=/run/current-system/sw/bin:${config.home.homeDirectory}/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin"
      ];
      ExecStart = randomDmsWallpaper;
    };
    Install.WantedBy = [ "niri.service" ];
  };

}
