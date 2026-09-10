{
  flake.nixosModules.development = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      python3
      uv
      ruff
      pyright
      python3Packages.jupyterlab

      # Keep native compiler wrappers and the build/debug toolchain in the
      # system profile so gcc/g++ are available to login shells and Neovim.
      gcc
      binutils
      clang
      clang-tools
      cmake
      meson
      ninja
      gdb
      lldb
      gnumake
      pkg-config
      cppcheck
      bear
      valgrind
      strace

      nodejs
      pnpm
      go
      rustc
      cargo
    ];
  };
}
