{ ... }:
{
  flake.nixosModules.niri = { pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        useNautilus = true;
      };

      environment.systemPackages = with pkgs; [
        xwayland-satellite
        wev
        wl-clipboard
        wl-clip-persist
        grim
        slurp
        satty
      ];
    };
}
