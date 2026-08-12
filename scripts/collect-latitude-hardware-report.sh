#!/usr/bin/env bash
set -u

# Collects diagnostic information only; does not modify hardware.nix,
# mounts, subvolumes, or system configuration.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="${LATITUDE_REPORT_DIR:-${REPO_ROOT}/diagnostics}"
REPORT_FILE="${REPORT_DIR}/latitude-hardware-report.txt"
TARGET_ROOT="${NIXOS_INSTALL_ROOT:-/}"

mkdir -p "$REPORT_DIR"
: > "$REPORT_FILE"

section() {
  {
    printf '\n===== %s =====\n' "$1"
  } >> "$REPORT_FILE"
}

run() {
  local label="$1"
  shift
  section "$label"
  printf '$' >> "$REPORT_FILE"
  printf ' %q' "$@" >> "$REPORT_FILE"
  printf '\n' >> "$REPORT_FILE"
  "$@" >> "$REPORT_FILE" 2>&1
  local rc=$?
  printf '[exit=%s]\n' "$rc" >> "$REPORT_FILE"
  return 0
}

run_shell() {
  local label="$1"
  local command="$2"
  section "$label"
  printf '$ %s\n' "$command" >> "$REPORT_FILE"
  REPO_ROOT="$REPO_ROOT" TARGET_ROOT="$TARGET_ROOT" bash -c "$command" >> "$REPORT_FILE" 2>&1
  local rc=$?
  printf '[exit=%s]\n' "$rc" >> "$REPORT_FILE"
  return 0
}

{
  printf '# Latitude hardware diagnostic report\n'
  printf '# Generated: %s\n' "$(date -Is)"
  printf '# This report is intended for debugging and contains no file contents from /home or /etc.\n'
  printf '# The script does not modify system configuration or repository configuration files.\n'
} >> "$REPORT_FILE"

run_shell "Environment" 'printf "id: "; id; printf "kernel: "; uname -a; printf "hostname: "; hostname'
run_shell "Tool availability" 'for c in nixos-generate-config btrfs findmnt lsblk blkid mountpoint; do printf "%s: " "$c"; command -v "$c" || true; done'
run_shell "Tool versions" 'nixos-generate-config --version 2>&1 || true; btrfs --version 2>&1 || true; findmnt --version 2>&1 || true; lsblk --version 2>&1 || true'
run "Root mount" findmnt -no TARGET,SOURCE,FSTYPE,UUID,PARTUUID,OPTIONS / 
run "Relevant mounts" findmnt -rn -t btrfs,vfat,ext4,xfs,bcachefs -o TARGET,SOURCE,FSTYPE,UUID,PARTUUID,OPTIONS
run "Block devices" lsblk -e7 -o NAME,PATH,TYPE,FSTYPE,LABEL,PARTLABEL,UUID,PARTUUID,FSAVAIL,FSUSE%,MOUNTPOINTS
run_shell "Partition metadata" 'if command -v udevadm >/dev/null 2>&1; then udevadm settle || true; fi; while read -r dev type; do [ "$type" = "disk" ] || continue; echo "--- $dev ---"; blkid "$dev" 2>/dev/null || true; if command -v sfdisk >/dev/null 2>&1; then sfdisk --dump "$dev" 2>/dev/null || true; fi; done < <(lsblk --list --paths --noheadings --raw --output NAME,TYPE)'
run "Btrfs filesystem for root" btrfs filesystem show /
run "Btrfs root subvolume" btrfs subvolume show /
run "Btrfs root subvolume list" btrfs subvolume list -p /
run_shell "Mountinfo root" 'grep -E "[[:space:]]/[[:space:]]" /proc/self/mountinfo || true'
run_shell "Btrfs kernel modules" 'lsmod | grep -E "^btrfs[[:space:]]" || true; grep -E "^btrfs[[:space:]]" /proc/filesystems || true'

section "nixos-generate-config normal"
GEN_CONFIG_CMD=(nixos-generate-config --show-hardware-config)
if [ "$TARGET_ROOT" != "/" ]; then
  GEN_CONFIG_CMD+=(--root "$TARGET_ROOT")
fi
printf '$' >> "$REPORT_FILE"
printf ' %q' "${GEN_CONFIG_CMD[@]}" >> "$REPORT_FILE"
printf '\n' >> "$REPORT_FILE"
"${GEN_CONFIG_CMD[@]}" >> "$REPORT_FILE" 2>&1
GEN_RC=$?
printf '[exit=%s]\n' "$GEN_RC" >> "$REPORT_FILE"

if [ "$GEN_RC" -ne 0 ]; then
  section "nixos-generate-config no-filesystems fallback"
  FALLBACK_CMD=("${GEN_CONFIG_CMD[@]}" --no-filesystems)
  printf '$' >> "$REPORT_FILE"
  printf ' %q' "${FALLBACK_CMD[@]}" >> "$REPORT_FILE"
  printf '\n' >> "$REPORT_FILE"
  "${FALLBACK_CMD[@]}" >> "$REPORT_FILE" 2>&1
  FALLBACK_RC=$?
  printf '[exit=%s]\n' "$FALLBACK_RC" >> "$REPORT_FILE"
fi

section "Repository context"
run_shell "Tracked Latitude hardware file metadata" 'git -C "$REPO_ROOT" status --short; git -C "$REPO_ROOT" log -1 --format="%h %s" -- scripts/generate-latitude-hardware.sh modules/hosts/latitude/hardware.nix; sha256sum "$REPO_ROOT/modules/hosts/latitude/hardware.nix" 2>/dev/null || true'

printf '\nReport saved to: %s\n' "$REPORT_FILE"
printf 'Review it before committing; this script never runs git add, commit, or push.\n'
