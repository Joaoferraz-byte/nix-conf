{ ... }:
{
  flake.nixosModules.appimage = { ... }:
    {
      # NixOS AppImages normally need the appimage-run FHS/bwrap wrapper.
      # Registering binfmt also makes direct execution and file-manager launch
      # use the same compatibility path instead of invoking the raw ELF.
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
}
