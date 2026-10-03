{ pkgs, ... }:
{
  flake.nixosModules.developmentKotlin = {
    environment.systemPackages = with pkgs; [
      jdk21 maven gradle
    ];
  };
}
