{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentJavaScript = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nodejs pnpm typescript typescript-language-server prettier
      ];
    };
}
