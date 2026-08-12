#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="${NIX_CONF_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
TARGET_ROOT="${NIXOS_TARGET_ROOT:-/}"
SOURCE_OVERRIDE="${NIXOS_HARDWARE_CONFIG_SOURCE:-}"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/nix-conf/hardware-backups/latitude"
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
  --target-root PATH  Mounted installed root. Use / for a running system.
  --source PATH        Explicit hardware-configuration.nix source.
  --help               Show this help.

The script never formats, partitions, mounts, or changes ACPI parameters.
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

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist: $REPO_ROOT"
TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist: $TARGET_ROOT"
HOST_DIR="${REPO_ROOT}/modules/hosts/latitude"
ENTRYPOINT_FILE="${HOST_DIR}/hardware.nix"
HARDWARE_FILE="${HOST_DIR}/hardware-configuration.nix"

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

require_mount() {
  local path="$1"
  local label="$2"
  [ -d "$path" ] || fail "$label directory is missing: $path"
  findmnt -M "$path" -no SOURCE,FSTYPE >/dev/null 2>&1 \
    || fail "$label is not mounted at $path. Mount the installed system before generating hardware configuration."
}

validate_target_mounts() {
  require_mount "$TARGET_ROOT" "Target root"
  require_mount "$TARGET_ROOT/boot" "EFI/system boot filesystem"
  printf 'Target root mount: '
  findmnt -M "$TARGET_ROOT" -no SOURCE,FSTYPE
  printf 'Boot mount: '
  findmnt -M "$TARGET_ROOT/boot" -no SOURCE,FSTYPE
}

find_fallback_source() {
  local candidate
  for candidate in \
    "$TARGET_ROOT/etc/nixos/hardware-configuration.nix" \
    "$TARGET_ROOT/etc/nixos/hardware.nix" \
    /etc/nixos/hardware-configuration.nix \
    /etc/nixos/hardware.nix; do
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
  grep -q 'fileSystems\.\|fileSystems\."' "$TEMP_FILE" \
    || fail "Detected hardware configuration contains no fileSystems entries: $SOURCE_LABEL"
  grep -q 'fileSystems\."/"' "$TEMP_FILE" \
    || fail "Detected hardware configuration has no root filesystem entry: $SOURCE_LABEL"
  grep -q 'fileSystems\."/boot"' "$TEMP_FILE" \
    || fail "Detected hardware configuration has no /boot entry although /boot is mounted."
  grep -qE 'BOOT-PARTUUID|CHANGE_ME|TODO|PLACEHOLDER|PARTUUID_HERE|UUID_HERE' "$TEMP_FILE" \
    && fail "Detected hardware configuration contains a placeholder device identifier: $SOURCE_LABEL"
  validate_device_references

  if command -v nix-instantiate >/dev/null 2>&1; then
    local parse_error="${TEMP_DIR}/nix-parse-error"
    if ! nix-instantiate --parse "$TEMP_FILE" >/dev/null 2> "$parse_error"; then
      if grep -qE 'daemon-socket.*Permission denied|getting status of /nix/var/nix' "$parse_error"; then
        printf 'Warning: skipped Nix parser check because the local daemon is unavailable.\n' >&2
        cat "$parse_error" >&2
      else
        cat "$parse_error" >&2
        fail "Nix parser rejected the detected hardware configuration."
      fi
    fi
  fi
}

[ -r "$ENTRYPOINT_FILE" ] || fail "Missing Latitude hardware entrypoint: $ENTRYPOINT_FILE"
grep -q 'hardware-configuration.nix' "$ENTRYPOINT_FILE" \
  || fail "Latitude hardware entrypoint does not import hardware-configuration.nix: $ENTRYPOINT_FILE"

if [ "$TARGET_ROOT" = "/" ]; then
  validate_target_mounts
else
  validate_target_mounts
fi

if [ -n "$SOURCE_OVERRIDE" ]; then
  SOURCE_OVERRIDE="$(realpath -e "$SOURCE_OVERRIDE")" || fail "Hardware source does not exist: $SOURCE_OVERRIDE"
  copy_hardware_source "$SOURCE_OVERRIDE"
  SOURCE_LABEL="$SOURCE_OVERRIDE"
elif command -v nixos-generate-config >/dev/null 2>&1; then
  printf 'Detecting hardware with nixos-generate-config under %s...\n' "$TARGET_ROOT"
  if run_as_root nixos-generate-config --root "$TARGET_ROOT" --show-hardware-config > "$TEMP_FILE" 2> "$GENERATOR_LOG"; then
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
