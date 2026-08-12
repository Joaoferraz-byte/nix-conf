#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOST_DIR="${REPO_ROOT}/modules/hosts/latitude"
ENTRYPOINT_FILE="${HOST_DIR}/hardware.nix"
HARDWARE_FILE="${HOST_DIR}/hardware-configuration.nix"
SOURCE_OVERRIDE="${NIXOS_HARDWARE_CONFIG_SOURCE:-}"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/nix-conf/hardware-backups/latitude"
TEMP_DIR="$(mktemp -d)"
TEMP_FILE="${TEMP_DIR}/hardware-configuration.nix"
GENERATOR_LOG="${TEMP_DIR}/nixos-generate-config.log"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || fail "Root privileges are required for hardware detection, but sudo is unavailable."
    sudo -- "$@"
  fi
}

copy_hardware_source() {
  local source="$1"
  if [ -r "$source" ]; then
    cp -- "$source" "$TEMP_FILE"
  else
    run_as_root cat -- "$source" > "$TEMP_FILE"
  fi
}

backup_file() {
  local source="$1"
  local name
  name="$(basename "$source")"
  if [ -e "$source" ]; then
    mkdir -p "$BACKUP_ROOT"
    install -m 0644 "$source" "$BACKUP_ROOT/${name}.$(date +%Y%m%d-%H%M%S)"
  fi
}

[ -r "$ENTRYPOINT_FILE" ] || fail "Missing Latitude hardware entrypoint: $ENTRYPOINT_FILE"
grep -q 'hardware-configuration.nix' "$ENTRYPOINT_FILE" \
  || fail "Latitude hardware entrypoint does not import hardware-configuration.nix: $ENTRYPOINT_FILE"

if [ -n "$SOURCE_OVERRIDE" ]; then
  [ -r "$SOURCE_OVERRIDE" ] || fail "Cannot read NIXOS_HARDWARE_CONFIG_SOURCE: $SOURCE_OVERRIDE"
  cp -- "$SOURCE_OVERRIDE" "$TEMP_FILE"
  SOURCE_LABEL="$SOURCE_OVERRIDE"
elif command -v nixos-generate-config >/dev/null 2>&1; then
  printf 'Detecting live Latitude hardware with nixos-generate-config...\n'
  if run_as_root nixos-generate-config --show-hardware-config > "$TEMP_FILE" 2> "$GENERATOR_LOG"; then
    SOURCE_LABEL="nixos-generate-config --show-hardware-config"
  else
    cat "$GENERATOR_LOG" >&2
    SOURCE_FILE=""
    for candidate in /etc/nixos/hardware-configuration.nix /etc/nixos/hardware.nix; do
      if [ -r "$candidate" ]; then
        SOURCE_FILE="$candidate"
        break
      fi
    done
    [ -n "$SOURCE_FILE" ] || fail "Hardware detection failed and no conventional hardware file exists under /etc/nixos."
    printf 'Using fallback hardware source: %s\n' "$SOURCE_FILE" >&2
    copy_hardware_source "$SOURCE_FILE"
    SOURCE_LABEL="$SOURCE_FILE"
  fi
else
  SOURCE_FILE=""
  for candidate in /etc/nixos/hardware-configuration.nix /etc/nixos/hardware.nix; do
    if [ -r "$candidate" ]; then
      SOURCE_FILE="$candidate"
      break
    fi
  done
  [ -n "$SOURCE_FILE" ] || fail "Install nixos-install-tools or set NIXOS_HARDWARE_CONFIG_SOURCE to a valid file."
  printf 'nixos-generate-config is unavailable; using fallback hardware source: %s\n' "$SOURCE_FILE" >&2
  cp -- "$SOURCE_FILE" "$TEMP_FILE"
  SOURCE_LABEL="$SOURCE_FILE"
fi

[ -s "$TEMP_FILE" ] || fail "Detected hardware configuration is empty: $SOURCE_LABEL"
grep -q 'fileSystems\.' "$TEMP_FILE" \
  || fail "Detected hardware configuration contains no fileSystems entries: $SOURCE_LABEL"
if grep -qE 'BOOT-PARTUUID|PARTUUID([-_]?(HERE|TODO|CHANGE_ME))|UUID=CHANGE_ME|/dev/disk/by-label/(nixos|CHANGE_ME)' "$TEMP_FILE"; then
  fail "Detected hardware configuration contains a placeholder device identifier: $SOURCE_LABEL"
fi

if command -v nix-instantiate >/dev/null 2>&1; then
  PARSE_ERROR="${TEMP_DIR}/nix-parse-error"
  if ! nix-instantiate --parse "$TEMP_FILE" >/dev/null 2> "$PARSE_ERROR"; then
    if grep -qE 'daemon-socket.*Permission denied|getting status of /nix/var/nix' "$PARSE_ERROR"; then
      printf 'Warning: skipped Nix parser check because the local daemon is unavailable.\n' >&2
      cat "$PARSE_ERROR" >&2
    else
      cat "$PARSE_ERROR" >&2
      fail "Nix parser rejected the detected hardware configuration."
    fi
  fi
fi

backup_file "$HARDWARE_FILE"
install -m 0644 "$TEMP_FILE" "$HARDWARE_FILE"

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || fail "Repository root is not a Git worktree: $REPO_ROOT"
git -C "$REPO_ROOT" add -- "$HARDWARE_FILE"
git -C "$REPO_ROOT" diff --cached --check -- "$HARDWARE_FILE"

printf 'Generated and staged: %s\n' "$HARDWARE_FILE"
printf 'Source: %s\n' "$SOURCE_LABEL"
printf 'Backup directory: %s\n' "$BACKUP_ROOT"
printf 'Review with: git -C %s diff --cached -- %s\n' "$REPO_ROOT" "${HARDWARE_FILE#${REPO_ROOT}/}"
