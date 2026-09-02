{ config, pkgs, ... }:
let
  vaultDirectory = "${config.home.homeDirectory}/Vault";
  git = "${pkgs.git}/bin/git";
  date = "${pkgs.coreutils}/bin/date";

  syncRepository = { repository, directory, label }:
    pkgs.writeShellScript "sync-livara-${label}" ''
      #!/usr/bin/env bash
      set -euo pipefail
      export GIT_TERMINAL_PROMPT=0

      repository="${repository}"
      directory="${directory}"
      mkdir -p "$(dirname "$directory")"

      if [[ ! -d "$directory/.git" ]]; then
        tmp="''${directory}.tmp.$$"
        backup="''${directory}.partial-backup.$$"
        rm -rf "$tmp"
        if [[ -e "$directory" || -L "$directory" ]]; then
          mv -- "$directory" "$backup"
        fi
        if ! ${git} clone --depth 1 "$repository" "$tmp"; then
          rm -rf "$tmp"
          if [[ -e "$backup" || -L "$backup" ]]; then
            mv -- "$backup" "$directory"
          fi
          exit 75
        fi
        mv -- "$tmp" "$directory"
        if [[ -e "$backup" || -L "$backup" ]]; then
          printf '%s\n' "Partial Vault preserved at $backup" >&2
        fi
        exit 0
      fi

      # Repair missing tracked files without overwriting local content. This
      # also clears stale skip-worktree flags left by manual working-tree edits.
      ${git} -C "$directory" update-index --no-skip-worktree --no-assume-unchanged -- . || exit 75
      ${git} -C "$directory" checkout-index -a --ignore-skip-worktree-bits || exit 75

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

  syncVault = syncRepository {
    repository = "https://github.com/Joaoferraz-byte/Vault.git";
    directory = vaultDirectory;
    label = "vault";
  };

  vaultSyncInteractive = pkgs.writeShellApplication {
    name = "livara-vault-sync";
    runtimeInputs = with pkgs; [ bash coreutils git libnotify ];
    text = ''
      set -Eeuo pipefail
      export GIT_TERMINAL_PROMPT=0
      directory="${vaultDirectory}"
      log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/livara/logs"
      mkdir -p "$log_dir"
      fetch_log="$(mktemp "$log_dir/vault-fetch.XXXXXX")"
      trap 'rm -f "$fetch_log"' EXIT

      notify() {
        notify-send -a "Livara Vault" "$1" "$2" 2>/dev/null || true
      }

      if [[ ! -d "$directory/.git" ]]; then
        notify "Vault" "Checkout não encontrado em $directory"
        exit 1
      fi

      branch="$(${git} -C "$directory" branch --show-current 2>/dev/null || true)"
      [[ -n "$branch" ]] || branch=main

      if ! ${git} -C "$directory" fetch --prune origin >"$fetch_log" 2>&1; then
        if grep -qiE 'authentication failed|could not read Username|permission denied|repository not found|terminal prompts disabled|access denied' "$fetch_log"; then
          notify "Autenticação do Vault necessária" "Configure o acesso Git de joaoferraz-byte e tente abrir o Vault novamente."
        else
          notify "Falha ao sincronizar o Vault" "$(tail -n 1 "$fetch_log")"
        fi
        exit 1
      fi

      dirty=false
      if [[ -n "$(${git} -C "$directory" status --porcelain --untracked-files=all)" ]]; then
        dirty=true
      fi
      stash_created=false
      if [[ "$dirty" == true ]]; then
        if ! ${git} -C "$directory" stash push --include-untracked -m "livara-vault-sync-$(date -u +%Y%m%dT%H%M%SZ)" >/dev/null; then
          notify "Vault não sincronizado" "Não foi possível preservar as alterações locais antes do merge."
          exit 1
        fi
        stash_created=true
      fi

      restore_local_changes() {
        if [[ "$stash_created" != true ]]; then
          return 0
        fi
        if ${git} -C "$directory" stash pop >/dev/null; then
          stash_created=false
          return 0
        fi
        notify "Conflito no Vault" "As alterações locais foram restauradas como conflito; resolva-as antes de continuar."
        return 1
      }

      remote_ref="origin/$branch"
      merge_mode="fast-forward"
      if ! ${git} -C "$directory" merge --ff-only "$remote_ref" >/dev/null 2>&1; then
        merge_mode="automatic merge"
        if ! ${git} -C "$directory" merge --no-edit "$remote_ref" >/dev/null 2>&1; then
          ${git} -C "$directory" merge --abort >/dev/null 2>&1 || true
          restore_local_changes || true
          notify "Conflito no Vault" "O pull não foi fast-forward e o merge automático precisa de resolução manual."
          exit 1
        fi
      fi

      restore_local_changes || exit 1
      ${git} -C "$directory" add -A
      staged_count="$(${git} -C "$directory" diff --cached --name-only | wc -l)"
      notify "Vault sincronizado" "$merge_mode concluído; $staged_count arquivo(s) preparado(s) no repositório do Vault."
    '';
  };

  saveVault = pkgs.writeShellScript "save-vault-on-exit" ''
    #!/usr/bin/env bash
    set -u
    export GIT_TERMINAL_PROMPT=0
    directory="${vaultDirectory}"
    log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/livara/logs"
    log_file="$log_dir/vault-sync.log"
    mkdir -p "$log_dir"
    log() { printf '[%s] %s\n' "$(${date} --iso-8601=seconds)" "$*" >> "$log_file"; }
    unstage() { ${git} -C "$directory" reset --mixed HEAD -- >/dev/null 2>&1 || true; }

    [[ -d "$directory/.git" ]] || { log "integrity guard: vault checkout missing; skip save"; exit 0; }

    required_paths=(
      "00 - Black Box"
      "01 - Source Notes"
      "02 - Projects"
      "03 - Daily Notes"
      "04 - Xournal++"
      "05 - References"
      "06 - Config"
    )
    for path in "''${required_paths[@]}"; do
      if [[ ! -d "$directory/$path" ]]; then
        log "integrity guard: canonical area missing: $path; skip save"
        exit 0
      fi
    done

    markdown_files="$(${pkgs.findutils}/bin/find "$directory" -type f -name '*.md' ! -path "$directory/.git/*" -print -quit)"
    if [[ -z "$markdown_files" ]]; then
      log "integrity guard: no Markdown files found; skip save"
      exit 0
    fi

    areas=(
      "00 - Black Box"
      "01 - Source Notes"
      "02 - Projects"
      "03 - Daily Notes"
      "04 - Xournal++"
      "05 - References"
      "06 - Config"
    )
    area_count=0
    for area in "''${areas[@]}"; do
      [[ -d "$directory/$area" ]] && area_count=$((area_count + 1))
    done
    if (( area_count < ''${#areas[@]} )); then
      log "integrity guard: canonical areas missing ($area_count/''${#areas[@]}); skip save"
      exit 0
    fi

    working_files="$(${pkgs.findutils}/bin/find "$directory" -type f ! -path "$directory/.git/*" | ${pkgs.coreutils}/bin/wc -l)"
    if (( working_files < 20 )); then
      log "integrity guard: suspiciously small checkout ($working_files files); skip save"
      exit 0
    fi

    status="$(${git} -C "$directory" status --porcelain --untracked-files=all)"
    if [[ -z "$status" ]]; then
      log "vault clean; nothing to commit"
      exit 0
    fi

    branch="$(${git} -C "$directory" branch --show-current 2>/dev/null || true)"
    [[ -n "$branch" ]] || branch=main
    rescue_branch="rescue/vault-save-$(${date} '+%Y%m%d-%H%M%S')"
    if ! ${git} -C "$directory" branch "$rescue_branch" HEAD >/dev/null 2>&1; then
      log "integrity guard: could not create local rescue branch; skip save"
      exit 0
    fi

    if ! ${git} -C "$directory" add -A; then
      unstage
      log "git add failed; working tree retained"
      exit 0
    fi

    head_files="$(${git} -C "$directory" ls-files | ${pkgs.coreutils}/bin/wc -l)"
    staged_deletions="$(${git} -C "$directory" diff --cached --name-status --diff-filter=D | ${pkgs.coreutils}/bin/wc -l)"
    if (( staged_deletions >= 50 )) || (( staged_deletions * 100 >= head_files * 20 )); then
      unstage
      log "integrity guard: refused staged deletion set (deleted=$staged_deletions tracked=$head_files rescue=$rescue_branch)"
      exit 0
    fi

    log "integrity preflight passed (files=$working_files deleted=$staged_deletions rescue=$rescue_branch)"
    if ${git} -C "$directory" diff --cached --quiet; then
      log "vault clean after stage; nothing to commit"
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
  home.packages = [ vaultSyncInteractive ];

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
