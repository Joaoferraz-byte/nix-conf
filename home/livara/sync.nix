{ config, pkgs, ... }:
let
  wallpapersDirectory = "${config.home.homeDirectory}/Wallpapers";
  vaultDirectory = "${config.home.homeDirectory}/Vault";
  git = "${pkgs.git}/bin/git";
  date = "${pkgs.coreutils}/bin/date";
  systemctl = "${pkgs.systemd}/bin/systemctl";

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

      # Pull only fast-forward changes. Local notes are never overwritten by a
      # login hook; the last valid checkout remains usable if networking or
      # remote history is unavailable.
      ${git} -C "$directory" fetch --prune origin || exit 75
      remote_head="$(${git} -C "$directory" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
      branch="''${remote_head#origin/}"
      [[ -n "$branch" ]] || branch="$(${git} -C "$directory" branch --show-current)"
      [[ -n "$branch" ]] || branch=main
      ${git} -C "$directory" merge --ff-only "origin/$branch" || exit 75
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

  saveVault = pkgs.writeShellScript "save-vault-on-exit" ''
    #!/usr/bin/env bash
    set -u
    export GIT_TERMINAL_PROMPT=0
    directory="${vaultDirectory}"
    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum/logs"
    log_file="$log_dir/vault-sync.log"
    mkdir -p "$log_dir"
    log() { printf '[%s] %s\n' "$(${date} --iso-8601=seconds)" "$*" >> "$log_file"; }

    [[ -d "$directory/.git" ]] || { log "vault checkout missing; skip save"; exit 0; }
    branch="$(${git} -C "$directory" branch --show-current 2>/dev/null || true)"
    [[ -n "$branch" ]] || branch=main
    ${git} -C "$directory" add -A || { log "git add failed"; exit 0; }
    if ${git} -C "$directory" diff --cached --quiet; then
      log "vault clean; nothing to commit"
      exit 0
    fi
    if ! ${git} -C "$directory" -c user.name="joaoferraz-byte" -c user.email="joaoferraz467@gmail.com" commit -m "chore: sync notes $(${date} '+%Y-%m-%d %H:%M:%S %z')"; then
      log "git commit failed"
      exit 0
    fi
    if ${pkgs.coreutils}/bin/timeout 30s ${git} -C "$directory" push origin "$branch"; then
      log "vault committed and pushed branch=$branch"
    else
      log "git push failed; local commit retained"
    fi
  '';

  zennotesLauncher = pkgs.writeShellScriptBin "zennotes-serpantinum" ''
    # Pull before opening the app. The save trap below handles normal app exit;
    # the session ExecStop unit covers logout and graceful shutdown.
    ${systemctl} --user start --no-block vault-sync.service >/dev/null 2>&1 || true
    set +e
    ${pkgs.flatpak}/bin/flatpak run org.zennotes.ZenNotes "$@"
    rc=$?
    set -e
    # Flatpak may return immediately after handing a URI to an existing
    # single-instance app. Follow the active application until it disappears,
    # with no daemon or long-lived watcher left behind.
    while ${pkgs.flatpak}/bin/flatpak ps --columns=application 2>/dev/null | grep -Fxq 'org.zennotes.ZenNotes'; do
      sleep 2
    done
    ${saveVault}
    exit "$rc"
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
  home.packages = [ zennotesLauncher ];

  home.file.".local/share/applications/org.zennotes.ZenNotes.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=ZenNotes
    Comment=ZenNotes with Vault synchronization
    Exec=${zennotesLauncher}/bin/zennotes-serpantinum %U
    Icon=org.zennotes.ZenNotes
    Terminal=false
    Categories=Office;Utility;
    MimeType=text/plain;text/markdown;
  '';

  systemd.user.services.wallpapers-sync = {
    Unit = {
      Description = "Sync the canonical wallpaper repository for Noctalia and Matugen";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = syncWallpapers;
    };
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.timers.wallpapers-sync = mkSyncTimer "wallpapers-sync";

  systemd.user.services.vault-sync = mkSyncService "Sync the Markdown vault repository" syncVault;
  systemd.user.timers.vault-sync = mkSyncTimer "vault-sync";

  # A remain-after-exit oneshot has no polling process. systemd invokes
  # ExecStop when graphical-session.target is torn down on logout or a graceful
  # poweroff, providing the final git add/commit/push opportunity.
  systemd.user.services.vault-save-on-session-stop = {
    Unit = {
      Description = "Save and push the Markdown vault when the user session stops";
      After = [ "vault-sync.service" ];
      Before = [ "shutdown.target" "reboot.target" "poweroff.target" ];
      Conflicts = [ "shutdown.target" "reboot.target" "poweroff.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = saveVault;
      TimeoutStopSec = 60;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
