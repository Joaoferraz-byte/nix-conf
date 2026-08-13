#!/usr/bin/env bash
set -uo pipefail

SCRIPT_PATH="$(realpath -e "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
DEFAULT_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="${NIX_CONF_REPO:-$DEFAULT_REPO_ROOT}"
TARGET_ROOT="${NIXOS_INSTALL_ROOT:-}"
OUTPUT="${LATITUDE_DIAGNOSTIC_OUTPUT:-/tmp/latitude-diagnostic.txt}"
PAD="${LATITUDE_DONTPAD_NAME:-nixosdotinst}"
UPLOAD=1

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: collect-latitude-diagnostic.sh [--local]

The default invocation detects the NixOS repository and installed root, writes
/tmp/latitude-diagnostic.txt, sanitizes identifiers and uploads the report to
https://dontpad.com/nixosdotinst.

Optional overrides:
  --local              Do not upload; keep only the local report.
  --repo PATH          Nix configuration repository.
  --target-root PATH  Installed NixOS root.
  --output PATH       Local report path.
  --upload NAME       Upload to a different Dontpad name.
  --help              Show this help.

The collector never formats, partitions, mounts, edits Nix configuration or
changes Git history. It only reads diagnostic information.
EOF
}

if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || fail "Run as root or install sudo."
  exec sudo -- "$0" "$@"
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --local|--no-upload)
      UPLOAD=0
      shift
      ;;
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
      UPLOAD=1
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

[ "${LATITUDE_NO_UPLOAD:-0}" = "1" ] && UPLOAD=0
command -v sed >/dev/null 2>&1 || fail "sed is required."
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required."
command -v findmnt >/dev/null 2>&1 || fail "findmnt is required."
command -v lsblk >/dev/null 2>&1 || fail "lsblk is required."

resolve_repo() {
  local candidate
  for candidate in "$REPO_ROOT" "$PWD" /root/.config/nixos /home/*/.config/nixos; do
    [ -d "$candidate" ] || continue
    if git -C "$candidate" rev-parse --show-toplevel >/dev/null 2>&1; then
      git -C "$candidate" rev-parse --show-toplevel
      return 0
    fi
  done
  return 1
}

has_nixos_markers() {
  local root="$1"
  local os_release="$root/etc/os-release"
  [ -d "$root/nix/store" ] || return 1
  [ -f "$root/etc/nixos/flake.nix" ] && return 0
  [ -f "$os_release" ] && grep -qE '(^|^)ID=nixos($|[[:space:]])' "$os_release" && return 0
  [ -d "$root/etc/nixos" ] && return 0
  return 1
}

is_temporary_filesystem() {
  case "$1" in
    overlay|squashfs|iso9660|tmpfs|ramfs|aufs) return 0 ;;
    *) return 1 ;;
  esac
}

detect_target_root() {
  local candidate target source fstype
  local -a candidates=(/ /mnt /target /mnt/nixos /media/nixos)
  while read -r target source fstype; do
    [ -n "$target" ] || continue
    candidates+=("$target")
  done < <(findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE 2>/dev/null || true)

  for candidate in "${candidates[@]}"; do
    [ -d "$candidate" ] || continue
    source="$(findmnt -M "$candidate" -no SOURCE 2>/dev/null || true)"
    fstype="$(findmnt -M "$candidate" -no FSTYPE 2>/dev/null || true)"
    is_temporary_filesystem "$fstype" && continue
    if has_nixos_markers "$candidate"; then
      realpath -e "$candidate"
      return 0
    fi
  done
  return 1
}

REPO_ROOT="$(resolve_repo || true)"
[ -n "$REPO_ROOT" ] || fail "Could not locate the Nix configuration Git repository. Run from its checkout or set NIX_CONF_REPO."

if [ -z "$TARGET_ROOT" ]; then
  TARGET_ROOT="$(detect_target_root || true)"
fi
[ -n "$TARGET_ROOT" ] || fail "Could not detect an installed NixOS root. Mount it and set NIXOS_INSTALL_ROOT, or run from the installed system."

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist."
TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist."
mkdir -p "$(dirname "$OUTPUT")" || fail "Cannot create report directory."

sanitize() {
  sed -E \
    -e 's#(/dev/disk/by-(uuid|partuuid)/)[[:alnum:]-]+#\1<redacted>#g' \
    -e 's/([[:space:]_=:-])([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})([^0-9a-fA-F-]|$)/\1<redacted-uuid>\3/g' \
    -e 's/([[:space:]_=:-])([0-9a-fA-F]{32})([^0-9a-fA-F]|$)/\1<redacted-id>\3/g' \
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
  printf '# Raw UUIDs, PARTUUIDs and home paths are redacted.\n'
  printf '# This collector does not modify system configuration or Git history.\n'
  printf '# Repository: %s\n' "$REPO_ROOT"
  printf '# Target root: %s\n' "$TARGET_ROOT"
} | sanitize >> "$OUTPUT"

run_shell "Context" 'printf "uid: "; id -u; printf "kernel: "; uname -srmo; printf "target-root: "; printf "%s\\n" "$TARGET_ROOT"'
run_shell "Tool availability" 'for c in nixos-generate-config findmnt lsblk blkid btrfs udevadm mount systemctl journalctl; do printf "%s: " "$c"; command -v "$c" || true; done'
run_shell "Tool versions" 'findmnt --version 2>&1 || true; lsblk --version 2>&1 || true; nixos-generate-config --version 2>&1 || true; btrfs --version 2>&1 || true'
run "Kernel command line" cat /proc/cmdline
run "Root mount" findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS "$TARGET_ROOT"
run "Relevant mounts" findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS
run "Block devices" lsblk --list --paths --noheadings --output NAME,TYPE,FSTYPE,PARTTYPE,PARTLABEL,LABEL,UUID,PARTUUID,MOUNTPOINTS
run_shell "Stable identifiers" 'lsblk --list --paths --noheadings --output NAME,TYPE,FSTYPE,PARTTYPE,PARTLABEL,LABEL,MOUNTPOINTS; printf "\\nblkid summary:\\n"; blkid 2>/dev/null || true'
run "Btrfs filesystem" btrfs filesystem show "$TARGET_ROOT"
run "Btrfs root subvolume" btrfs subvolume show "$TARGET_ROOT"
run "Btrfs subvolume list" btrfs subvolume list -p "$TARGET_ROOT"
run_shell "Mountinfo" 'grep -E "[[:space:]]/(boot|home|nix|)[[:space:]]" /proc/self/mountinfo || true'
run_shell "Failed units" 'systemctl --failed --no-legend --no-pager 2>&1 || true'
run_shell "Relevant boot errors" 'journalctl -b -p err..alert --no-pager 2>&1 | grep -Ei "btrfs|mount|boot|emergency|filesystem|nixos-generate|failed|error|uuid|subvolume" | tail -n 200 || true'

section "nixos-generate-config output"
if command -v nixos-generate-config >/dev/null 2>&1; then
  if [ "$TARGET_ROOT" = "/" ]; then
    nixos-generate-config --show-hardware-config 2>&1 | sanitize >> "$OUTPUT"
  else
    nixos-generate-config --root "$TARGET_ROOT" --show-hardware-config 2>&1 | sanitize >> "$OUTPUT"
  fi
  printf '[exit=%s]\n' "${PIPESTATUS[0]}" >> "$OUTPUT"
else
  printf 'nixos-generate-config is unavailable.\n' >> "$OUTPUT"
fi

section "Repository context"
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_ROOT" status --short 2>&1 | sanitize >> "$OUTPUT"
  git -C "$REPO_ROOT" log -1 --format='%h %s' -- scripts/generate-hardware.sh modules/hosts/latitude/hardware.nix 2>&1 | sanitize >> "$OUTPUT"
  sha256sum "$REPO_ROOT/modules/hosts/latitude/hardware.nix" 2>/dev/null | sanitize >> "$OUTPUT" || true
else
  printf 'Repository is not a Git worktree.\n' >> "$OUTPUT"
fi

printf '\nReport saved to: %s\n' "$OUTPUT"

if [ "$UPLOAD" -eq 1 ]; then
  command -v curl >/dev/null 2>&1 || fail "curl is required for automatic upload."
  case "$PAD" in
    *[!A-Za-z0-9._-]*) fail "Dontpad name contains unsupported characters." ;;
  esac
  PAGE_URL="https://dontpad.com/${PAD}"
  API_BASE="https://api.dontpad.com"
  BODY_URL="${API_BASE}/${PAD}.body.json?lastModified=0"
  body_json="$(curl --fail --silent --show-error --location --max-time 30 \
    -H 'Accept: application/json' "$BODY_URL")" || \
    fail "Could not read the Dontpad version."
  last_modified="$(printf '%s' "$body_json" | sed -nE 's/.*"lastModified"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p')"
  [ -n "$last_modified" ] || fail "Dontpad returned an invalid version: $body_json"
  response="$(curl --fail --silent --show-error --location --max-time 30 \
    -H 'Accept: application/json' \
    --data-urlencode "text@${OUTPUT}" \
    --data-urlencode "lastModified=${last_modified}" \
    --data-urlencode 'force=false' \
    "${API_BASE}/${PAD}")" || \
    fail "Dontpad rejected the report upload."
  case "$response" in
    *[!0-9]*) fail "Dontpad returned an invalid upload response: $response" ;;
  esac
  printf 'Sanitized report uploaded to: %s\n' "$PAGE_URL"
else
  printf 'Upload disabled; report remains at %s\n' "$OUTPUT"
fi
