{ pkgs, ... }: {
  flake.nixosModules.firejail = { pkgs, ... }: {
    # Enable firejail SUID sandbox globally
    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        # Brave browser — Chromium-based, use the upstream brave profile
        brave = {
          executable = "${pkgs.brave}/bin/brave";
          profile = "${pkgs.firejail}/etc/firejail/brave.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
            "--dbus-user.talk=org.freedesktop.secrets"
          ];
        };
        # Vesktop (Vencord-patched Discord client)
        vesktop = {
          executable = "${pkgs.vesktop}/bin/vesktop";
          profile = "${pkgs.firejail}/etc/firejail/vesktop.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
            "--dbus-user.talk=org.kde.StatusNotifierWatcher"
          ];
        };
        # Telegram Desktop
        telegram-desktop = {
          executable = "${pkgs.telegram-desktop}/bin/telegram-desktop";
          profile = "${pkgs.firejail}/etc/firejail/telegram-desktop.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
            "--dbus-user.talk=org.kde.StatusNotifierWatcher"
          ];
        };
        # Obsidian — note-taking app (Electron)
        obsidian = {
          executable = "${pkgs.obsidian}/bin/obsidian";
          profile = "${pkgs.firejail}/etc/firejail/obsidian.profile";
          extraArgs = [
            "--env=NIXOS_OZONE_WL=1"
            "--dbus-user.talk=org.freedesktop.Notifications"
          ];
        };
        # mpv — media player
        mpv = {
          executable = "${pkgs.mpv}/bin/mpv";
          profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
        };
      };
    };
  };
}
