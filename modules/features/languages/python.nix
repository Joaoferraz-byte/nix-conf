{ pkgs, ... }:
{
  flake.nixosModules.developmentPython = {
    environment.systemPackages = with pkgs; [
      python3 uv ruff pyright python3Packages.jupyterlab python3Packages.debugpy
      pkg-config ffmpeg
    ];
  };
}
