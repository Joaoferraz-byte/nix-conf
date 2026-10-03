{ pkgs, ... }:
{
  flake.nixosModules.developmentRust = {
    environment.systemPackages = with pkgs; [
      rustc cargo rust-analyzer rustfmt clippy
    ];
  };
}
