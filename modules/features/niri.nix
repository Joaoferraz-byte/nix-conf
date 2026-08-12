{ inputs, ... }:
{
  flake.nixosModules.niri = { pkgs, ... }:
    {
      imports = [ inputs.shell-conf.nixosModules.niri ];

      programs.niri.enable = true;

      environment.systemPackages = with pkgs; [
        xwayland-satellite
        waybar
        fuzzel
        kitty
        dunst
        libnotify
      ];
    };
}
