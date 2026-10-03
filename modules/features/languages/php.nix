{ pkgs, ... }:
{
  flake.nixosModules.developmentPhp = {
    environment.systemPackages = with pkgs; [
      php phpPackages.composer
    ];
  };
}
