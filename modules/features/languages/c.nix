{ pkgs, ... }:
{
  flake.nixosModules.developmentC = {
    environment.systemPackages = with pkgs; [
      gcc binutils clang clang-tools cmake ninja gnumake pkg-config
      gdb lldb cppcheck bear
    ];
  };
}
