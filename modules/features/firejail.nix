{ pkgs, ... }: {
  flake.nixosModules.firejail = { pkgs, ... }: {
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
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
            "--dbus-user.talk=org.kde.StatusNotifierWatcher"
          ];
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
        obsidian = {
          executable = "${pkgs.obsidian}/bin/obsidian";
          profile = "${pkgs.firejail}/etc/firejail/obsidian.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
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
