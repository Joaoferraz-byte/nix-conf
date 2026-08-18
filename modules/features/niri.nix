{ ... }:
{
  flake.nixosModules.niri = { config, lib, pkgs, ... }:
    {
      config = lib.mkIf (config.desktop.profile.compositor == "niri") {
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
    };
}
