#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="${NIX_CONF_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
TARGET_ROOT="${NIXOS_TARGET_ROOT:-}"
SOURCE_OVERRIDE="${NIXOS_HARDWARE_CONFIG_SOURCE:-}"
BACKUP_ROOT="${NIX_CONF_HARDWARE_BACKUP_DIR:-${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/nix-conf/hardware-backups/latitude}"
TEMP_DIR="$(mktemp -d)"
TEMP_FILE="${TEMP_DIR}/hardware-configuration.nix"
GENERATOR_LOG="${TEMP_DIR}/nixos-generate-config.log"

HOST_DIR=""
ENTRYPOINT_FILE=""
HARDWARE_FILE=""
SOURCE_LABEL=""

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: generate-latitude-hardware.sh [options]

Options:
  --repo PATH          Repository containing modules/hosts/latitude.
  --target-root PATH  Mounted installed root. If omitted, use / or a discovered target.
  --source PATH        Explicit hardware-configuration.nix source.
  --help               Show this help.

The script never formats, partitions, mounts, or changes ACPI parameters.
It calls the official nixos-generate-config command after the target mounts
have been selected and verified.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--repository)
      [ "$#" -ge 2 ] || fail "$1 requires a path."
      REPO_ROOT="$2"
      shift 2
      ;;
    --target-root|--root)
      [ "$#" -ge 2 ] || fail "$1 requires a path."
      TARGET_ROOT="$2"
      shift 2
      ;;
    --source)
      [ "$#" -ge 2 ] || fail "$1 requires a path."
      SOURCE_OVERRIDE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

command -v findmnt >/dev/null 2>&1 || fail "findmnt is required."
command -v realpath >/dev/null 2>&1 || fail "realpath is required."

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist: $REPO_ROOT"
HOST_DIR="${REPO_ROOT}/modules/hosts/latitude"
ENTRYPOINT_FILE="${HOST_DIR}/hardware.nix"
HARDWARE_FILE="${HOST_DIR}/hardware-configuration.nix"
[ -r "$ENTRYPOINT_FILE" ] || fail "Missing Latitude hardware entrypoint: $ENTRYPOINT_FILE"
grep -q 'hardware-configuration.nix' "$ENTRYPOINT_FILE" \
  || fail "Latitude hardware entrypoint does not import hardware-configuration.nix: $ENTRYPOINT_FILE"

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

mount_info() {
  local path="$1"
  findmnt -M "$path" -no SOURCE,FSTYPE 2>/dev/null || true
}

is_valid_nixos_root() {
  local path="$1"
  local source fstype
  [ -d "$path/etc" ] || return 1
  source="$(findmnt -M "$path" -no SOURCE 2>/dev/null || true)"
  fstype="$(findmnt -M "$path" -no FSTYPE 2>/dev/null || true)"
  [ -n "$source" ] || return 1
  case "$fstype" in
    overlay|squashfs|iso9660|tmpfs) return 1 ;;
  esac
  [ -e "$path/etc/NIXOS" ] || [ -d "$path/nix/store" ] || return 1
}

discover_target_root() {
  local candidate
  local -a candidates=()
  for candidate in / /mnt /target /mnt/nixos /media/nixos; do
    [ -d "$candidate" ] || continue
    is_valid_nixos_root "$candidate" && candidates+=("$candidate")
  done
  case "${#candidates[@]}" in
    0) fail "No mounted NixOS root was detected. Use --target-root PATH after mounting the installed system." ;;
    1) TARGET_ROOT="${candidates[0]}" ;;
    *)
      printf 'Candidate NixOS roots:\n' >&2
      printf '  %s\n' "${candidates[@]}" >&2
      fail "More than one NixOS root was detected; use --target-root explicitly."
      ;;
  esac
}

require_target_root() {
  local source fstype
  [ -d "$TARGET_ROOT/etc" ] || fail "Target root has no etc directory: $TARGET_ROOT"
  source="$(findmnt -M "$TARGET_ROOT" -no SOURCE 2>/dev/null || true)"
  fstype="$(findmnt -M "$TARGET_ROOT" -no FSTYPE 2>/dev/null || true)"
  [ -n "$source" ] || fail "Target root is not mounted: $TARGET_ROOT"
  case "$fstype" in
    overlay|squashfs|iso9660|tmpfs) fail "Target root is a Live ISO or temporary filesystem: $TARGET_ROOT ($fstype)" ;;
  esac
  printf 'Target root: %s (%s, %s)\n' "$TARGET_ROOT" "$source" "$fstype"
}

require_boot_mount() {
  local boot_path="${TARGET_ROOT%/}/boot"
  local source fstype
  [ -d "$boot_path" ] || fail "Target root has no boot directory: $boot_path"
  source="$(findmnt -M "$boot_path" -no SOURCE 2>/dev/null || true)"
  fstype="$(findmnt -M "$boot_path" -no FSTYPE 2>/dev/null || true)"
  [ -n "$source" ] || fail "Boot filesystem is not mounted at $boot_path. Run recover-latitude-boot.sh first or mount it explicitly."
  printf 'Boot path: %s (%s, %s)\n' "$boot_path" "$source" "$fstype"
}

find_fallback_source() {
  local candidate
  for candidate in \
    "$TARGET_ROOT/etc/nixos/hardware-configuration.nix" \
    "$TARGET_ROOT/etc/nixos/hardware.nix"; do
    if [ -r "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

validate_device_references() {
  local device
  local -a devices
  mapfile -t devices < <(sed -nE 's/^[[:space:]]*device[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*;.*/\1/p' "$TEMP_FILE")
  [ "${#devices[@]}" -gt 0 ] || fail "Generated hardware configuration contains no device references: $SOURCE_LABEL"

  for device in "${devices[@]}"; do
    case "$device" in
      /dev/*)
        [ -e "$device" ] || fail "Generated device does not exist in the current environment: $device"
        ;;
    esac
  done
}

validate_generated_config() {
  [ -s "$TEMP_FILE" ] || fail "Detected hardware configuration is empty: $SOURCE_LABEL"
  grep -qE 'fileSystems\.["/]+' "$TEMP_FILE" \
    || fail "Detected hardware configuration contains no fileSystems entries: $SOURCE_LABEL"
  grep -q 'fileSystems."/"' "$TEMP_FILE" \
    || fail "Detected hardware configuration has no root filesystem entry: $SOURCE_LABEL"
  grep -qE 'BOOT-PARTUUID|CHANGE_ME|TODO|PLACEHOLDER|PARTUUID_HERE|UUID_HERE|ROOT-PARTUUID' "$TEMP_FILE" \
    && fail "Detected hardware configuration contains a placeholder device identifier: $SOURCE_LABEL"
  validate_device_references

  if command -v nix-instantiate >/dev/null 2>&1; then
    local parse_error="${TEMP_DIR}/nix-parse-error"
    if ! nix-instantiate --parse "$TEMP_FILE" >/dev/null 2> "$parse_error"; then
      if grep -qE 'daemon-socket.*Permission denied|getting status of /nix/var/nix' "$parse_error"; then
        printf 'Warning: skipped Nix parser check because the local daemon is unavailable.\n' >&2
      else
        cat "$parse_error" >&2
        fail "Nix parser rejected the detected hardware configuration."
      fi
    fi
  fi
}

[ -n "$TARGET_ROOT" ] || discover_target_root
TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist: $TARGET_ROOT"
require_target_root
require_boot_mount
[ -w "$HOST_DIR" ] || fail "Repository host directory is not writable: $HOST_DIR. Remount the target root read-write or choose a writable checkout."

if [ -n "$SOURCE_OVERRIDE" ]; then
  SOURCE_OVERRIDE="$(realpath -e "$SOURCE_OVERRIDE")" || fail "Hardware source does not exist: $SOURCE_OVERRIDE"
  copy_hardware_source "$SOURCE_OVERRIDE"
  SOURCE_LABEL="$SOURCE_OVERRIDE"
elif command -v nixos-generate-config >/dev/null 2>&1; then
  printf 'Detecting hardware with nixos-generate-config under %s...\n' "$TARGET_ROOT"
  if [ "$TARGET_ROOT" = "/" ]; then
    if run_as_root nixos-generate-config --show-hardware-config > "$TEMP_FILE" 2> "$GENERATOR_LOG"; then
      SOURCE_LABEL="nixos-generate-config --show-hardware-config"
    else
      cat "$GENERATOR_LOG" >&2
      SOURCE_FILE="$(find_fallback_source || true)"
      [ -n "$SOURCE_FILE" ] || fail "Hardware detection failed and no conventional hardware file exists under the target root."
      printf 'Using fallback hardware source: %s\n' "$SOURCE_FILE" >&2
      copy_hardware_source "$SOURCE_FILE"
      SOURCE_LABEL="$SOURCE_FILE"
    fi
  elif run_as_root nixos-generate-config --root "$TARGET_ROOT" --show-hardware-config > "$TEMP_FILE" 2> "$GENERATOR_LOG"; then
    SOURCE_LABEL="nixos-generate-config --root $TARGET_ROOT --show-hardware-config"
  else
    cat "$GENERATOR_LOG" >&2
    SOURCE_FILE="$(find_fallback_source || true)"
    [ -n "$SOURCE_FILE" ] || fail "Hardware detection failed and no conventional hardware file exists under the target root."
    printf 'Using fallback hardware source: %s\n' "$SOURCE_FILE" >&2
    copy_hardware_source "$SOURCE_FILE"
    SOURCE_LABEL="$SOURCE_FILE"
  fi
else
  SOURCE_FILE="$(find_fallback_source || true)"
  [ -n "$SOURCE_FILE" ] || fail "Install nixos-install-tools or set --source to a valid hardware file."
  printf 'nixos-generate-config is unavailable; using fallback hardware source: %s\n' "$SOURCE_FILE" >&2
  copy_hardware_source "$SOURCE_FILE"
  SOURCE_LABEL="$SOURCE_FILE"
fi

validate_generated_config
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
