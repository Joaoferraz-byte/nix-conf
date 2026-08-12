#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${NIX_CONF_REPO_ROOT:-$(dirname "$SCRIPT_DIR")}"
TARGET_ROOT="/"
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
  --target-root PATH  Mounted installed root; defaults to /.
  --dry-run            Print inventory and candidate ESP without mounting.
  --help               Show this help.

The helper only mounts an already existing EFI System Partition. It never
formats, partitions, edits firmware, changes ACPI parameters, or guesses a
root filesystem in a Live ISO.
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

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist: $REPO_ROOT"
TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist: $TARGET_ROOT"
BOOT_DIR="${TARGET_ROOT%/}/boot"

[ "$(id -u)" -eq 0 ] || fail "Run this recovery helper as root from the emergency shell or with sudo."
command -v findmnt >/dev/null 2>&1 || fail "findmnt is required."
command -v lsblk >/dev/null 2>&1 || fail "lsblk is required."
command -v mount >/dev/null 2>&1 || fail "mount is required."

if command -v udevadm >/dev/null 2>&1; then
  udevadm settle || true
fi

printf '%s\n' 'Detected block-device inventory:'
lsblk --list --paths --output NAME,TYPE,FSTYPE,PARTTYPE,PARTLABEL,LABEL,UUID,PARTUUID,MOUNTPOINTS

if findmnt -M "$BOOT_DIR" -no SOURCE,FSTYPE >/dev/null 2>&1; then
  printf 'Boot filesystem is already mounted: '
  findmnt -M "$BOOT_DIR" -no SOURCE,FSTYPE
else
  [ -d "$BOOT_DIR" ] || fail "Boot directory does not exist: $BOOT_DIR"

  candidates=()
  while read -r path type fstype parttype; do
    [ "$type" = "part" ] || continue
    [ "$fstype" = "vfat" ] || continue
    [ "${parttype,,}" = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ] || continue
    candidates+=("$path")
  done < <(lsblk --list --paths --noheadings --raw --output NAME,TYPE,FSTYPE,PARTTYPE)

  case "${#candidates[@]}" in
    0)
      fail "No unmounted EFI System Partition was detected. Inspect the inventory and mount the correct ESP manually."
      ;;
    1)
      ESP_DEVICE="${candidates[0]}"
      ;;
    *)
      printf 'Candidate ESPs:\n' >&2
      printf '  %s\n' "${candidates[@]}" >&2
      fail "More than one possible ESP was detected; refusing to guess."
      ;;
  esac

  printf 'Detected unique ESP: %s\n' "$ESP_DEVICE"
  [ "$DRY_RUN" -eq 1 ] && exit 0

  mount "$ESP_DEVICE" "$BOOT_DIR"
  printf 'Mounted ESP at %s: ' "$BOOT_DIR"
  findmnt -M "$BOOT_DIR" -no SOURCE,FSTYPE
fi

[ "$DRY_RUN" -eq 1 ] && exit 0

"$SCRIPT_DIR/generate-latitude-hardware.sh" \
  --repo "$REPO_ROOT" \
  --target-root "$TARGET_ROOT"

printf '%s\n' 'Recovery generation completed. Review the staged hardware file before rebuilding.'
