{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentPython = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        python3 uv ruff pyright python3Packages.jupyterlab python3Packages.debugpy
      pkg-config ffmpeg
      ];
    };
}
