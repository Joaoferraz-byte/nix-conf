{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentRust = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rustc cargo rust-analyzer rustfmt clippy
      ];
    };
}
