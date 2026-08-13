#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_ROOT="${NIXOS_INSTALL_ROOT:-/}"
OUTPUT="${LATITUDE_DIAGNOSTIC_OUTPUT:-${REPO_ROOT}/diagnostics/latitude-diagnostic.txt}"
PAD=""

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: collect-latitude-diagnostic.sh [options]

Options:
  --repo PATH          Nix configuration repository.
  --target-root PATH  Installed NixOS root, default: /.
  --output PATH       Local sanitized report path.
  --upload NAME       Publish the sanitized report to https://dontpad.com/NAME.
  --help              Show this help.

The collector never formats, partitions, mounts, edits configuration, or runs git
commands that change history. Upload is opt-in and sends only the sanitized report.
EOF
}

if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || fail "Run as root or install sudo."
  exec sudo -- "$0" "$@"
fi

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
    --output)
      [ "$#" -ge 2 ] || fail "$1 requires a path."
      OUTPUT="$2"
      shift 2
      ;;
    --upload)
      [ "$#" -ge 2 ] || fail "$1 requires a Dontpad name."
      PAD="$2"
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

command -v sed >/dev/null 2>&1 || fail "sed is required."
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required."
command -v findmnt >/dev/null 2>&1 || fail "findmnt is required."
command -v lsblk >/dev/null 2>&1 || fail "lsblk is required."

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist: $REPO_ROOT"
TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist: $TARGET_ROOT"
mkdir -p "$(dirname "$OUTPUT")" || fail "Cannot create report directory."

sanitize() {
  sed -E \
    -e 's#(/dev/disk/by-(uuid|partuuid)/)[[:alnum:]-]+#\1<redacted>#g' \
    -e 's/([[:space:]_=:-])([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})([^0-9a-fA-F-]|$)/\1<redacted-uuid>\3/g' \
    -e 's/([[:space:]_=:-])([0-9a-fA-F]{32})([^0-9a-fA-F]|$)/\1<redacted-id>\3/g' \
    -e "s#${HOME:-/home/[^/]+}#<home>#g" \
    -e 's#/home/[^/[:space:]]+#<home>#g'
}

section() {
  printf '\n===== %s =====\n' "$1" >> "$OUTPUT"
}

run() {
  local label="$1"
  shift
  section "$label"
  printf '$' >> "$OUTPUT"
  printf ' %q' "$@" >> "$OUTPUT"
  printf '\n' >> "$OUTPUT"
  "$@" 2>&1 | sanitize >> "$OUTPUT"
  local rc=${PIPESTATUS[0]}
  printf '[exit=%s]\n' "$rc" >> "$OUTPUT"
}

run_shell() {
  local label="$1"
  local command="$2"
  section "$label"
  printf '$ %s\n' "$command" >> "$OUTPUT"
  TARGET_ROOT="$TARGET_ROOT" REPO_ROOT="$REPO_ROOT" bash -c "$command" 2>&1 | sanitize >> "$OUTPUT"
  local rc=${PIPESTATUS[0]}
  printf '[exit=%s]\n' "$rc" >> "$OUTPUT"
}

: > "$OUTPUT"
{
  printf '# Sanitized Latitude hardware diagnostic\n'
  printf '# Generated: %s\n' "$(date -Is)"
  printf '# Raw UUIDs, PARTUUIDs, home paths and hostnames are redacted.\n'
  printf '# This collector does not modify disks, mounts, Nix configuration or Git history.\n'
} >> "$OUTPUT"

run_shell "Context" 'printf "uid: "; id -u; printf "kernel: "; uname -srmo; printf "target-root: "; printf "%s\\n" "$TARGET_ROOT"'
run_shell "Tool availability" 'for c in nixos-generate-config findmnt lsblk blkid btrfs udevadm mount systemctl journalctl; do printf "%s: " "$c"; command -v "$c" || true; done'
run_shell "Tool versions" 'findmnt --version 2>&1 || true; lsblk --version 2>&1 || true; nixos-generate-config --version 2>&1 || true; btrfs --version 2>&1 || true'
run "Kernel command line" cat /proc/cmdline
run "Root mount" findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS "$TARGET_ROOT"
run "Relevant mounts" findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS
run "Block devices" lsblk --list --paths --noheadings --raw --output NAME,TYPE,FSTYPE,PARTTYPE,PARTLABEL,LABEL,UUID,PARTUUID,MOUNTPOINTS
run_shell "Stable identifiers" 'for dev in /dev/sda /dev/sda1 /dev/sda2 /dev/sda3 /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/nvme0n1p3; do [ -e "$dev" ] && { printf "--- %s ---\\n" "$dev"; blkid "$dev" 2>/dev/null || true; }; done'
run "Btrfs filesystem" btrfs filesystem show "$TARGET_ROOT"
run "Btrfs root subvolume" btrfs subvolume show "$TARGET_ROOT"
run "Btrfs subvolume list" btrfs subvolume list -p "$TARGET_ROOT"
run_shell "Mountinfo" 'grep -E "[[:space:]]/(boot|home|nix|)[[:space:]]" /proc/self/mountinfo || true'
run_shell "Failed units" 'systemctl --failed --no-legend --no-pager 2>&1 || true'
run_shell "Relevant boot errors" 'journalctl -b -p err..alert --no-pager 2>&1 | grep -Ei "btrfs|mount|boot|emergency|filesystem|nixos-generate|failed|error|uuid|subvolume" | tail -n 200 || true'

if command -v nixos-generate-config >/dev/null 2>&1; then
  section "nixos-generate-config output"
  if [ "$TARGET_ROOT" = "/" ]; then
    nixos-generate-config --show-hardware-config 2>&1 | sanitize >> "$OUTPUT"
  else
    nixos-generate-config --root "$TARGET_ROOT" --show-hardware-config 2>&1 | sanitize >> "$OUTPUT"
  fi
  printf '[exit=%s]\n' "${PIPESTATUS[0]}" >> "$OUTPUT"
else
  section "nixos-generate-config output"
  printf 'nixos-generate-config is unavailable.\n' >> "$OUTPUT"
fi

section "Repository context"
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_ROOT" status --short 2>&1 | sanitize >> "$OUTPUT"
  git -C "$REPO_ROOT" log -1 --format='%h %s' -- scripts/generate-latitude-hardware.sh modules/hosts/latitude/hardware.nix 2>&1 | sanitize >> "$OUTPUT"
  sha256sum "$REPO_ROOT/modules/hosts/latitude/hardware.nix" 2>/dev/null | sanitize >> "$OUTPUT" || true
else
  printf 'Repository is not a Git worktree: %s\n' "$REPO_ROOT" >> "$OUTPUT"
fi

printf '\nReport saved to: %s\n' "$OUTPUT"

if [ -n "$PAD" ]; then
  command -v curl >/dev/null 2>&1 || fail "curl is required for --upload."
  case "$PAD" in
    *[!A-Za-z0-9._-]*) fail "Dontpad name contains unsupported characters." ;;
  esac
  URL="https://dontpad.com/${PAD}"
  curl --fail --silent --show-error --location \
    --data-urlencode "text@${OUTPUT}" "$URL" >/dev/null
  printf 'Sanitized report uploaded to: %s\n' "$URL"
else
  printf 'No upload requested. Use --upload PAD_NAME only after reviewing the report.\n'
fi
