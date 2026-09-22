{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  # The selected desktop shell owns the idle/lock/suspend policy. Keeping a
  # second idle daemon here would create independent timers and race on lock,
  # monitor power and suspend actions.

  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/Pictures/Screenshots" "${home}/Videos/Recordings"
  '';

  # Niri does not start a desktop-specific polkit agent. GParted uses polkit
  # for its privileged operations and otherwise fails with "No authentication
  # agent found" even when system polkit itself is enabled.
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "Polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
