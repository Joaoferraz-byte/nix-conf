{
  flake.nixosModules.development = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      python3
      uv
      ruff
      pyright
      python3Packages.jupyterlab

      clang
      clang-tools
      cmake
      gdb
      gnumake
      pkg-config
      strace

      nodejs
      pnpm
      go
      rustc
      cargo
    ];
  };
}
