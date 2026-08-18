#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Installation aborted at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd -- "$SCRIPT_DIR"

INSTALL_LOG="${NIX_CONF_LOG_FILE:-${XDG_STATE_HOME:-${HOME}/.local/state}/nix-conf/install.log}"

init_log() {
  mkdir -p "$(dirname -- "$INSTALL_LOG")" || {
    printf '%s\n' "Error: cannot create log directory: $(dirname -- "$INSTALL_LOG")" >&2
    exit 1
  }
  : > "$INSTALL_LOG" || {
    printf '%s\n' "Error: cannot write installer log: $INSTALL_LOG" >&2
    exit 1
  }
  # Keep exactly one current log per run while still showing the same output
  # interactively. No temporary metadata/rebuild log is created elsewhere.
  exec > >(tee -a "$INSTALL_LOG") 2>&1
  printf '%s\n' "Installer log: $INSTALL_LOG"
}

if [ "$(id -u)" -eq 0 ]; then
  printf '%s\n' 'Error: run ./install.sh as the checkout owner, not as root. The installer uses sudo only for privileged system operations.' >&2
    exit 1
fi

init_log

preflight_git_worktree() {
  local git_root git_dir git_objects git_index
  command -v git >/dev/null 2>&1 || {
    printf '%s\n' 'Error: Git is required.' >&2
    exit 1
  }
  git_root="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)" || {
    printf '%s\n' "Error: the installer directory is not a Git worktree: $SCRIPT_DIR" >&2
    exit 1
  }
  [ "$git_root" = "$SCRIPT_DIR" ] || {
    printf '%s\n' "Error: the installer must run from the repository root: $SCRIPT_DIR" >&2
    exit 1
  }
  git_dir="$(git -C "$SCRIPT_DIR" rev-parse --git-dir)"
  git_objects="$(git -C "$SCRIPT_DIR" rev-parse --git-path objects)"
  git_index="$(git -C "$SCRIPT_DIR" rev-parse --git-path index)"
  [ -w "$git_objects" ] || {
    printf '%s\n' "Error: Git object storage is not writable: $git_objects" >&2
    printf '%s\n' "Fix with: sudo chown -R \"$(id -u):$(id -g)\" \"$git_dir\"" >&2
    exit 1
  }
  if [ -e "$git_index" ] && [ ! -w "$git_index" ]; then
    printf '%s\n' "Error: Git index is not writable: $git_index" >&2
    printf '%s\n' "Fix with: sudo chown -R \"$(id -u):$(id -g)\" \"$git_dir\"" >&2
    exit 1
  fi
  if git -C "$SCRIPT_DIR" diff --name-only --diff-filter=U | grep -q .; then
    printf '%s\n' 'Error: the checkout contains unresolved Git conflicts.' >&2
    exit 1
  fi
  if [ -f "$SCRIPT_DIR/flake.lock" ] && grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$SCRIPT_DIR/flake.lock" >/dev/null; then
    printf '%s\n' 'Error: flake.lock contains merge-conflict markers. Resolve or restore it before running the installer.' >&2
    exit 1
  fi
}

preflight_git_worktree

verify_locked_flake() {
  [ "${NIX_CONF_UPDATE_FLAKE:-0}" = "1" ] && return 0
  printf '%s\n' 'Checking locked flake metadata...'
  if nix flake metadata --no-update-lock-file "$SCRIPT_DIR" >/dev/null; then
    return 0
  fi
  printf '%s\n' 'Error: flake.nix and flake.lock are not synchronized, or a locked input cannot be resolved.' >&2
  printf '%s\n' 'If the input revision was intentionally changed, run:' >&2
  printf '%s\n' '  NIX_CONF_UPDATE_FLAKE=1 NIX_CONF_UPDATE_INPUTS="shell-conf vim-conf" ./install.sh' >&2
  exit 1
}

update_flake_inputs_if_requested() {
  local lock_backup status
  local -a update_inputs=()

  [ "${NIX_CONF_UPDATE_FLAKE:-0}" = "1" ] || return 0
  [ -w "$SCRIPT_DIR/flake.lock" ] || {
    printf '%s\n' 'Error: NIX_CONF_UPDATE_FLAKE=1 requires a writable flake.lock.' >&2
    exit 1
  }

  lock_backup="${TMPDIR:-/tmp}/nix-conf-flake.lock.$(date +%Y%m%d-%H%M%S)"
  cp -p "$SCRIPT_DIR/flake.lock" "$lock_backup"
  printf '%s\n' 'Updating flake inputs by explicit request before entering the devShell...'

  if [ -n "${NIX_CONF_UPDATE_INPUTS:-}" ]; then
    read -r -a update_inputs <<< "${NIX_CONF_UPDATE_INPUTS}"
    if nix flake update "${update_inputs[@]}"; then
      :
    else
      status=$?
      cp -p "$lock_backup" "$SCRIPT_DIR/flake.lock"
      printf '%s\n' "Error: flake input update failed with exit code $status; restored $lock_backup." >&2
      exit "$status"
    fi
  elif nix flake update; then
    :
  else
    status=$?
    cp -p "$lock_backup" "$SCRIPT_DIR/flake.lock"
    printf '%s\n' "Error: flake input update failed with exit code $status; restored $lock_backup." >&2
    exit "$status"
  fi

  printf 'Previous lockfile backup: %s\n' "$lock_backup"
  export NIX_CONF_LOCK_UPDATED=1
}

if [ "${NIX_CONF_DEV_SHELL:-0}" != "1" ]; then
  command -v nix >/dev/null 2>&1 || {
    printf '%s\n' 'Error: the Nix command is required.' >&2
    exit 1
  }
  verify_locked_flake
  update_flake_inputs_if_requested
  export NIX_CONF_DEV_SHELL=1
  exec nix develop --no-update-lock-file "$SCRIPT_DIR" --command bash "$SCRIPT_DIR/install.sh" "$@"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FLAKE_TARGET=""
REBOOT=""
REBUILD_MODE="${NIX_CONF_REBUILD_MODE:-switch}"

fail() {
  printf '%b\n' "${RED}$*${NC}" >&2
  exit 1
}

case "$REBUILD_MODE" in
  dry-activate|test|boot|switch) ;;
  *) fail "Unsupported NIX_CONF_REBUILD_MODE '$REBUILD_MODE'. Use dry-activate, test, boot, or switch." ;;
esac

if [ -n "${NIX_CONF_HOST:-}" ]; then
  FLAKE_TARGET="${NIX_CONF_HOST}"
elif [ "${NIX_CONF_NONINTERACTIVE:-0}" = "1" ]; then
  FLAKE_TARGET="${NIX_CONF_DEFAULT_HOST:-latitude}"
else
  printf '%b\n' "${GREEN}=== nix-conf installation ===${NC}"
  printf '\nAvailable hosts:\n'
  printf '  1) myMachine  - Desktop AMD + NVIDIA\n'
  printf '  2) latitude   - Dell Latitude 5410 (Intel)\n\n'
  read -r -p 'Select host [1-2]: ' HOST_CHOICE
  case "$HOST_CHOICE" in
    1) FLAKE_TARGET='myMachine' ;;
    2) FLAKE_TARGET='latitude' ;;
    *) fail 'Invalid host selection.' ;;
  esac
fi

normalize_flake_host() {
  local normalized
  normalized="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]_-')"
  case "$normalized" in
    latitude|latitude5410|delllatitude|delllatitude5410) printf 'latitude\n' ;;
    mymachine|desktop|desktopamdnvidia) printf 'myMachine\n' ;;
    *) return 1 ;;
  esac
}

if ! FLAKE_TARGET="$(normalize_flake_host "$FLAKE_TARGET")"; then
  fail "Unsupported host: $FLAKE_TARGET. Use latitude or myMachine."
fi

preflight_repository() {
  local git_root git_dir git_objects git_index

  preflight_git_worktree
  command -v git >/dev/null 2>&1 || fail 'Git is required.'
  command -v nix >/dev/null 2>&1 || fail 'Nix is required.'
  command -v nixos-rebuild >/dev/null 2>&1 || fail 'nixos-rebuild is required.'
  command -v sudo >/dev/null 2>&1 || fail 'sudo is required for system activation.'

  git_root="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)" \
    || fail "The installer directory is not a Git worktree: $SCRIPT_DIR"
  [ "$git_root" = "$SCRIPT_DIR" ] \
    || fail "The installer must run from the repository root: $SCRIPT_DIR"

  git_dir="$(git -C "$SCRIPT_DIR" rev-parse --git-dir)"
  git_objects="$(git -C "$SCRIPT_DIR" rev-parse --git-path objects)"
  git_index="$(git -C "$SCRIPT_DIR" rev-parse --git-path index)"
  [ -w "$git_objects" ] \
    || fail "Git object storage is not writable: $git_objects. Fix ownership with: sudo chown -R \"$(id -u):$(id -g)\" \"$git_dir\""
  if [ -e "$git_index" ] && [ ! -w "$git_index" ]; then
    fail "Git index is not writable: $git_index. Fix ownership with: sudo chown -R \"$(id -u):$(id -g)\" \"$git_dir\""
  fi

  git -C "$SCRIPT_DIR" ls-files --error-unmatch flake.nix flake.lock >/dev/null \
    || fail 'flake.nix and flake.lock must be tracked files.'
  if git -C "$SCRIPT_DIR" diff --name-only --diff-filter=U | grep -q .; then
    fail 'The checkout contains unresolved Git conflicts. Resolve them before running the installer.'
  fi
  if grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$SCRIPT_DIR/flake.lock" >/dev/null; then
    fail 'flake.lock contains merge-conflict markers. Restore or resolve it before running the installer.'
  fi

  if [ "${NIX_CONF_UPDATE_FLAKE:-0}" = '1' ]; then
    [ -w "$SCRIPT_DIR/flake.lock" ] \
      || fail 'NIX_CONF_UPDATE_FLAKE=1 requires a writable flake.lock.'
  fi
}

configure_hardware() {
  local status
  local -a target_args=()
  if [ -n "${NIXOS_TARGET_ROOT:-}" ]; then
    target_args=(--target-root "$NIXOS_TARGET_ROOT")
  fi
  printf '%b\n' "${YELLOW}Detecting and validating hardware for $FLAKE_TARGET...${NC}"
  if "$SCRIPT_DIR/scripts/generate-hardware.sh" --repo "$SCRIPT_DIR" --host "$FLAKE_TARGET" "${target_args[@]}"; then
    return 0
  else
    status=$?
  fi
  if [ "$FLAKE_TARGET" = 'latitude' ] && [ "${NIX_CONF_AUTO_DIAGNOSTIC:-1}" = '1' ] \
    && [ -x "$SCRIPT_DIR/scripts/collect-latitude-diagnostic.sh" ]; then
    printf '%b\n' "${YELLOW}Hardware detection failed; collecting a sanitized Latitude diagnostic...${NC}" >&2
    "$SCRIPT_DIR/scripts/collect-latitude-diagnostic.sh" --repo "$SCRIPT_DIR" \
      || printf '%b\n' "${YELLOW}Diagnostic collection failed; preserving the original hardware error.${NC}" >&2
  fi
  return "$status"
}

preflight_repository

printf '%b\n' "${GREEN}Repository: $SCRIPT_DIR${NC}"
printf '%b\n' "${GREEN}Selected host: $FLAKE_TARGET${NC}"
printf '%b\n' "${GREEN}Rebuild mode: $REBUILD_MODE${NC}"
printf '%s\n' "Current commit: $(git -C "$SCRIPT_DIR" rev-parse --short HEAD)"

if configure_hardware; then
  :
else
  status=$?
  printf '%b\n' "${RED}Hardware detection failed. No rebuild was attempted.${NC}" >&2
  exit "$status"
fi

if [ "${NIX_CONF_UPDATE_FLAKE:-0}" = '1' ] && [ "${NIX_CONF_LOCK_UPDATED:-0}" != '1' ]; then
  update_flake_inputs_if_requested
elif [ "${NIX_CONF_UPDATE_FLAKE:-0}" = '0' ]; then
  printf '%b\n' "${GREEN}Using locked flake inputs. Set NIX_CONF_UPDATE_FLAKE=1 to update them.${NC}"
else
  printf '%b\n' "${GREEN}Flake inputs were updated before entering the devShell.${NC}"
fi

printf '%b\n' "${YELLOW}Running nixos-rebuild $REBUILD_MODE for $FLAKE_TARGET...${NC}"
REBUILD_CMD=(sudo nixos-rebuild "$REBUILD_MODE" --flake "$SCRIPT_DIR#$FLAKE_TARGET" --show-trace)
set +e
"${REBUILD_CMD[@]}"
REBUILD_STATUS=$?
set -e
if [ "$REBUILD_STATUS" -ne 0 ]; then
  printf '%b\n' "${RED}nixos-rebuild failed with exit code $REBUILD_STATUS.${NC}" >&2
  printf 'Latest log: %s\n' "$INSTALL_LOG" >&2
  printf '%s\n' 'The previous generation remains available. Inspect it with:' >&2
  printf '%s\n' '  sudo nixos-rebuild list-generations' >&2
  printf '%s\n' 'If the current system is unusable, recover with:' >&2
  printf '%s\n' '  sudo nixos-rebuild --rollback switch' >&2
  exit "$REBUILD_STATUS"
fi

printf '%b\n' "${GREEN}Rebuild successful.${NC}"
if [ "${NIX_CONF_NONINTERACTIVE:-0}" = '1' ] || [ "$REBUILD_MODE" != 'switch' ]; then
  exit 0
fi
read -r -p 'Reboot now? [y/N] ' REBOOT
case "$REBOOT" in
  y|Y|yes) sudo reboot ;;
  *) printf '%s\n' 'Reboot skipped.' ;;
esac
