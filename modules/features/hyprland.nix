{ self, ... }: {
  flake.nixosModules.hyprland = { pkgs, lib, config, ... }:
    let
      hyprlandUwsmSession = pkgs.writeTextFile {
        name = "hyprland-uwsm";
        destination = "/share/wayland-sessions/hyprland-uwsm.desktop";
        text = ''
          [Desktop Entry]
          Name=Hyprland (UWSM)
          Comment=Hyprland compositor managed by UWSM
          Exec=${lib.getExe config.programs.uwsm.package} start -F -e -D Hyprland -- /run/current-system/sw/bin/start-hyprland
          Type=Application
          DesktopNames=Hyprland
          Keywords=hyprland;wayland;compositor;
        '';
        derivationArgs.passthru.providedSessions = [ "hyprland-uwsm" ];
      };
    in {
      programs.hyprland = {
        enable = true;
        withUWSM = false;
        xwayland.enable = true;
      };
      programs.uwsm.enable = true;

      environment.systemPackages = with pkgs; [
        hyprlandUwsmSession
        grim
        slurp
        wl-clipboard
        cliphist
        brightnessctl
        bibata-cursors
        wev
        playerctl
        hyprpicker
        ydotool
      ];

      services.displayManager.sessionPackages = [ hyprlandUwsmSession ];

    };

  flake.homeManagerModules.hyprland = { pkgs, ... }: {
    home.pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    wayland.systemd.target = "graphical-session.target";
  };
}
