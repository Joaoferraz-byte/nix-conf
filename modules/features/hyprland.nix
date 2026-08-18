{ self, ... }:
{
  flake.nixosModules.hyprland = { config, lib, pkgs, ... }:
    {
      config = lib.mkIf (config.desktop.profile.compositor == "hyprland") {
        programs.hyprland = {
          enable = true;
          withUWSM = true;
          xwayland.enable = true;
        };

        xdg.portal = {
          extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
          config.hyprland.default = [ "hyprland" "gtk" ];
        };

        environment.systemPackages = with pkgs; [
          grim
          grimblast
          slurp
          satty
          wl-clipboard
          wl-clip-persist
          cliphist
          brightnessctl
          bibata-cursors
          hyprpicker
          hyprsunset
          playerctl
          wev
          ydotool
        ];
      };
    };
}
