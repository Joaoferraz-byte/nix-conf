{ pkgs, ... }: {
  flake.nixosModules.firejail = { pkgs, ... }: {
    # The upstream Vesktop profile already grants Notifications and portal access.
    # Its join-or-start rule rejects late D-Bus CLI options, so extra policy lives
    # in the profile-local include loaded before that rule.
    environment.etc."firejail/vesktop.local".text = ''
      dbus-user.talk org.kde.StatusNotifierWatcher
    '';

    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        brave = {
          executable = "${pkgs.brave}/bin/brave";
          profile = "${pkgs.firejail}/etc/firejail/brave.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
            "--dbus-user.talk=org.freedesktop.secrets"
          ];
        };
        vesktop = {
          executable = "${pkgs.vesktop}/bin/vesktop";
          profile = "${pkgs.firejail}/etc/firejail/vesktop.profile";
          extraArgs = [ "--env=NIXOS_OZONE_WL=1" ];
        };
        telegram-desktop = {
          executable = "${pkgs.telegram-desktop}/bin/telegram-desktop";
          profile = "${pkgs.firejail}/etc/firejail/telegram-desktop.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
            "--dbus-user.talk=org.kde.StatusNotifierWatcher"
          ];
        };
        mpv = {
          executable = "${pkgs.mpv}/bin/mpv";
          profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
        };
      };
    };
  };
}
