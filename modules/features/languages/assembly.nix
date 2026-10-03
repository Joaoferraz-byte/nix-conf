{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentAssembly = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        binutils llvm clang clang-tools gdb lldb
      ];
    };
}
