{ pkgs, ... }:
{
  flake.nixosModules.developmentAssembly = {
    environment.systemPackages = with pkgs; [
      binutils llvm clang clang-tools gdb lldb
    ];
  };
}
