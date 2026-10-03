{ pkgs, ... }:
{
  flake.nixosModules.developmentCpp = {
    environment.systemPackages = with pkgs; [
      gcc clang clang-tools cmake ninja gnumake pkg-config
      gdb lldb cppcheck bear valgrind
    ];
  };
}
