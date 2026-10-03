{ pkgs, ... }:
{
  flake.nixosModules.developmentJavaScript = {
    environment.systemPackages = with pkgs; [
      nodejs pnpm typescript typescript-language-server prettier
    ];
  };
}
