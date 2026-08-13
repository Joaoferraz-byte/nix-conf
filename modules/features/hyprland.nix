{ self, ... }:
{
  flake.nixosModules.hyprland = { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

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

}
