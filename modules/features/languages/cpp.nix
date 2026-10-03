{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentCpp = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        gcc clang clang-tools cmake ninja gnumake pkg-config
      gdb lldb cppcheck bear valgrind
      ];
    };
}
