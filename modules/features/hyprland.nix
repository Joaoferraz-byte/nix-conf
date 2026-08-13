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

  flake.homeManagerModules.hyprland = { pkgs, ... }:
    {
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
