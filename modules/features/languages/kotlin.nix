{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentKotlin = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        jdk21 maven gradle
      ];
    };
}
