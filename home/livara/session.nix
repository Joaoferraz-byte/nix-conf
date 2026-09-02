{ config, lib, ... }:
let
  home = config.home.homeDirectory;
in
{
  # Noctalia owns the idle/lock/suspend policy through its declarative
  # [idle] configuration. Keeping a second idle daemon here would create two
  # independent timers and race on lock, monitor power and suspend actions.

  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/Pictures/Screenshots"
  '';

}
