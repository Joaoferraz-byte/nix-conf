#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${NIX_CONF_REPO_ROOT:-$(dirname "$SCRIPT_DIR")}"
TARGET_ROOT="${NIXOS_TARGET_ROOT:-}"
ESP_DEVICE="${NIXOS_ESP_DEVICE:-}"
DRY_RUN=0

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: recover-latitude-boot.sh [options]

Options:
  --repo PATH          Repository containing modules/hosts/latitude.
  --target-root PATH  Existing NixOS root mount. If omitted, detect it.
  --esp DEVICE         Existing EFI System Partition. If omitted, detect it.
  --dry-run            Print inventory and candidates without mounting.
  --help               Show this help.

The helper never formats, partitions, edits firmware, changes ACPI parameters,
or guesses when multiple installed roots or ESPs are possible.
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
    --esp|--boot-device)
      [ "$#" -ge 2 ] || fail "$1 requires a device."
      ESP_DEVICE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
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
command -v lsblk >/dev/null 2>&1 || fail "lsblk is required."
command -v realpath >/dev/null 2>&1 || fail "realpath is required."
command -v mount >/dev/null 2>&1 || fail "mount is required."

if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || fail "Run as root or install sudo."
  exec sudo -- "$0" "$@"
fi

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist: $REPO_ROOT"

if command -v udevadm >/dev/null 2>&1; then
  udevadm settle || true
fi

printf '%s\n' 'Detected block-device inventory:'
lsblk --list --paths --output NAME,TYPE,FSTYPE,PARTTYPE,PARTLABEL,LABEL,UUID,PARTUUID,MOUNTPOINTS

is_mounted_target() {
  local path="$1"
  findmnt -M "$path" -no SOURCE,FSTYPE >/dev/null 2>&1
}

is_valid_nixos_root() {
  local path="$1"
  local source fstype
  [ -d "$path/etc/nixos" ] || return 1
  source="$(findmnt -M "$path" -no SOURCE 2>/dev/null || true)"
  fstype="$(findmnt -M "$path" -no FSTYPE 2>/dev/null || true)"
  [ -n "$source" ] || return 1
  case "$fstype" in
    overlay|squashfs|iso9660|tmpfs) return 1 ;;
  esac
  return 0
}

discover_target_root() {
  local candidate
  local -a candidates=()

  for candidate in / /mnt /target /mnt/nixos /media/nixos; do
    [ -d "$candidate" ] || continue
    is_valid_nixos_root "$candidate" && candidates+=("$candidate")
  done

  case "${#candidates[@]}" in
    0)
      fail "No mounted NixOS root with etc/nixos was detected. Use --target-root /mnt after mounting the installed root."
      ;;
    1)
      TARGET_ROOT="${candidates[0]}"
      ;;
    *)
      printf 'Candidate NixOS roots:\n' >&2
      printf '  %s\n' "${candidates[@]}" >&2
      fail "More than one NixOS root was detected; use --target-root explicitly."
      ;;
  esac
}

validate_esp_device() {
  local device="$1"
  local type fstype parttype
  [ -b "$device" ] || fail "ESP is not a block device: $device"
  read -r type fstype parttype < <(lsblk --noheadings --raw --output TYPE,FSTYPE,PARTTYPE "$device")
  [ "$type" = "part" ] || fail "ESP path is not a partition: $device"
  [ "$fstype" = "vfat" ] || fail "ESP is not vfat: $device ($fstype)"
  [ "${parttype,,}" = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ] \
    || fail "Partition is not an EFI System Partition: $device ($parttype)"
}

discover_esp() {
  local path type fstype parttype mountpoints
  local -a candidates=()
  while read -r path type fstype parttype mountpoints; do
    [ "$type" = "part" ] || continue
    [ "$fstype" = "vfat" ] || continue
    [ "${parttype,,}" = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ] || continue
    case "$mountpoints" in
      *"$BOOT_DIR"*) return 0 ;;
      *) candidates+=("$path") ;;
    esac
  done < <(lsblk --list --paths --noheadings --raw --output NAME,TYPE,FSTYPE,PARTTYPE,MOUNTPOINTS)

  case "${#candidates[@]}" in
    0) fail "No unmounted EFI System Partition was detected. Unlock or mount the existing ESP manually." ;;
    1) ESP_DEVICE="${candidates[0]}" ;;
    *)
      printf 'Candidate EFI System Partitions:\n' >&2
      printf '  %s\n' "${candidates[@]}" >&2
      fail "More than one ESP was detected; use --esp DEVICE explicitly."
      ;;
  esac
}

if [ -z "$TARGET_ROOT" ]; then
  discover_target_root
else
  TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist: $TARGET_ROOT"
  is_valid_nixos_root "$TARGET_ROOT" || fail "Target root is not a mounted NixOS filesystem: $TARGET_ROOT"
fi

BOOT_DIR="${TARGET_ROOT%/}/boot"
[ -d "$BOOT_DIR" ] || fail "Boot directory does not exist: $BOOT_DIR"

printf 'Selected NixOS root: %s\n' "$TARGET_ROOT"
findmnt -M "$TARGET_ROOT" --noheadings --raw --output SOURCE,FSTYPE,TARGET

if is_mounted_target "$BOOT_DIR"; then
  printf 'Existing boot mount: '
  findmnt -M "$BOOT_DIR" --noheadings --raw --output SOURCE,FSTYPE,TARGET
else
  if [ -z "$ESP_DEVICE" ]; then
    discover_esp
  fi
  validate_esp_device "$ESP_DEVICE"
  [ "$DRY_RUN" -eq 1 ] && {
    printf 'Would mount existing ESP %s at %s\n' "$ESP_DEVICE" "$BOOT_DIR"
    exit 0
  }
  mount "$ESP_DEVICE" "$BOOT_DIR"
  printf 'Mounted existing ESP: '
  findmnt -M "$BOOT_DIR" --noheadings --raw --output SOURCE,FSTYPE,TARGET
fi

[ "$DRY_RUN" -eq 1 ] && exit 0

"$SCRIPT_DIR/generate-latitude-hardware.sh" \
  --repo "$REPO_ROOT" \
  --target-root "$TARGET_ROOT"

printf '%s\n' 'Hardware generation completed. Review the staged file before rebuilding.'
