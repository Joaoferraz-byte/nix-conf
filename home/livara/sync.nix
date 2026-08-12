{ config, pkgs, ... }:
let
  wallpapersDirectory = "${config.home.homeDirectory}/Wallpapers";
  vaultDirectory = "${config.home.homeDirectory}/Vault";
  git = "${pkgs.git}/bin/git";

  syncWallpapers = pkgs.writeShellScript "sync-wallpapers" ''
    set -eu
    repository="https://github.com/Joaoferraz-byte/Wallpapers.git"
    directory="${wallpapersDirectory}"

    if [ ! -d "$directory/.git" ]; then
      ${git} clone "$repository" "$directory"
    else
      ${git} -C "$directory" pull --ff-only
    fi
  '';

  syncVault = pkgs.writeShellScript "sync-vault" ''
    set -eu
    repository="git@github.com:Joaoferraz-byte/Vault.git"
    directory="${vaultDirectory}"

    if [ ! -d "$directory/.git" ]; then
      ${git} clone "$repository" "$directory"
    else
      ${git} -C "$directory" pull --ff-only
    fi
  '';

  mkSyncTimer = service: {
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "6h";
      Persistent = true;
      Unit = "${service}.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  mkSyncService = description: script: {
    Unit = {
      Description = description;
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = script;
    };
  };
in
{
  systemd.user.services.wallpapers-sync = mkSyncService "Sync the wallpaper repository" syncWallpapers;
  systemd.user.timers.wallpapers-sync = mkSyncTimer "wallpapers-sync";

  systemd.user.services.vault-sync = mkSyncService "Sync the Vault repository" syncVault;
  systemd.user.timers.vault-sync = mkSyncTimer "vault-sync";
}
