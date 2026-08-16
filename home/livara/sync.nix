{ config, pkgs, ... }:
let
  wallpapersDirectory = "${config.home.homeDirectory}/Wallpapers";
  vaultDirectory = "${config.home.homeDirectory}/Vault";
  git = "${pkgs.git}/bin/git";

  syncRepository = { repository, directory, label }:
    pkgs.writeShellScript "sync-${label}" ''
      #!/usr/bin/env bash
      set -euo pipefail
      export GIT_TERMINAL_PROMPT=0

      repository="${repository}"
      directory="${directory}"
      mkdir -p "$(dirname "$directory")"

      if [[ ! -d "$directory/.git" ]]; then
        tmp="''${directory}.tmp.$$"
        rm -rf "$tmp"
        if ! ${git} clone --depth 1 "$repository" "$tmp"; then
          rm -rf "$tmp"
          exit 75
        fi
        mv "$tmp" "$directory"
        exit 0
      fi

      # Keep the last valid checkout if the network is unavailable or the
      # remote history cannot be fast-forwarded. The shell remains usable.
      ${git} -C "$directory" fetch --prune origin || exit 75
      ${git} -C "$directory" merge --ff-only "origin/HEAD" || exit 75
    '';

  syncWallpapers = syncRepository {
    repository = "https://github.com/Joaoferraz-byte/Wallpapers.git";
    directory = wallpapersDirectory;
    label = "wallpapers";
  };

  syncVault = syncRepository {
    repository = "git@github.com:Joaoferraz-byte/Vault.git";
    directory = vaultDirectory;
    label = "vault";
  };

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
  systemd.user.services.wallpapers-sync = {
    Unit = {
      Description = "Sync the canonical wallpaper repository and apply its theme";
      After = [ "network-online.target" "serpantinum-wallpaper-daemon.service" ];
      Wants = [ "network-online.target" "serpantinum-wallpaper-daemon.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = syncWallpapers;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  systemd.user.timers.wallpapers-sync = mkSyncTimer "wallpapers-sync";

  systemd.user.services.vault-sync = mkSyncService "Sync the Markdown vault repository" syncVault;
  systemd.user.timers.vault-sync = mkSyncTimer "vault-sync";
}
