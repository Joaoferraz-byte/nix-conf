{
  flake.nixosModules.virtualization = { config, lib, pkgs, ... }:
    let
      cfg = config.desktop.virtualization;
    in
    {
      options.desktop.virtualization.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "User that manages local libvirt virtual machines.";
      };

      config = {
        virtualisation.libvirtd.enable = true;
        virtualisation.spiceUSBRedirection.enable = true;
        programs.virt-manager.enable = true;

        environment.systemPackages = with pkgs; [
          virt-manager
          virt-viewer
          spice-gtk
        ];

        users.users.${cfg.userName}.extraGroups = lib.mkAfter [
          "libvirtd"
        ];
      };
    };
}
