{ ... }: {
  flake.nixosModules.desktop-portals = { pkgs, ... }: {
    services.udisks2.enable = true;
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.udisks2.filesystem-mount" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };
  };
}
