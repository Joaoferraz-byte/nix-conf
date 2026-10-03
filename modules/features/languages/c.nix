{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentC = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        gcc binutils clang clang-tools cmake ninja gnumake pkg-config
      gdb lldb cppcheck bear
      ];
    };
}
