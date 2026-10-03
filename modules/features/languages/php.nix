{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentPhp = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        php phpPackages.composer
      ];
    };
}
