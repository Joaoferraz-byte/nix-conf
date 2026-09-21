{ config, lib, ... }:
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

}
