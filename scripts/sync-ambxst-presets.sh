#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# sync-ambxst-presets.sh
# ════════════════════════════════════════════════════════════════════════════
# Synchronizes the user's current Ambxst configuration (stored in
# $AMBXST_CONFIG_ROOT/config/) back to the shell-conf preset directory
# that ships with the flake.
#
# This enables a round-trip workflow:
#   1. Shell-conf HM module copies assets/presets/Ambxst Default/ → config dir
#   2. User edits config via Ambxst UI (modifies JSON files in config dir)
#   3. This script runs automatically via systemd timer to push changes back
#      to the preset source in the shell-conf repo.
#   4. User commits and pushes shell-conf to GitHub to persist changes.
#
# Default shell-conf path: /home/livara/Projects/shell-conf
# ════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────
CONFIG_ROOT="${AMBXST_CONFIG_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/ambxst}"
CONFIG_DIR="${CONFIG_ROOT}/config"
SHELL_CONF_DIR="${SHELL_CONF_DIR:-/home/livara/Projects/shell-conf}"

PRESET_NAME="Ambxst Default"
PRESET_DIR=""

# Files that should never be overwritten from user state
EXCLUDED_FILES=(
  "system.json"
  "ai.json"
  "prefix.json"
  "weather.json"
  "general.json"
)

# ── Helper Functions ──────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Synchronize user Ambxst config back to the shell-conf preset directory.

Options:
  --shell-conf-dir DIR    Override default shell-conf path
                          (default: /home/livara/Projects/shell-conf)
  --config-root DIR       Override AMBXST_CONFIG_ROOT
  --list-files            List files that would be synced (dry-run)
  --silent                Suppress output (for automated runs)
  -h, --help              Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --list-files
  $(basename "$0") --silent
EOF
  exit 0
}

info()  { [[ "$SILENT" == "true" ]] || echo "[INFO] $*"; }
warn()  { echo "[WARN] $*" >&2; }
err()   { echo "[ERROR] $*" >&2; exit 1; }

# Check if a file should be excluded from sync
is_excluded() {
  local filename="$1"
  for excluded in "${EXCLUDED_FILES[@]}"; do
    if [[ "$filename" == "$excluded" ]]; then
      return 0
    fi
  done
  return 1
}

# ── Argument Parsing ──────────────────────────────────────────────────────

DRY_RUN=false
SILENT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell-conf-dir)
      SHELL_CONF_DIR="$2"
      shift 2
      ;;
    --config-root)
      CONFIG_ROOT="$2"
      CONFIG_DIR="${CONFIG_ROOT}/config"
      shift 2
      ;;
    --list-files)
      DRY_RUN=true
      shift
      ;;
    --silent)
      SILENT=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      err "Unknown option: $1"
      ;;
  esac
done

# ── Validation ────────────────────────────────────────────────────────────

PRESET_DIR="${SHELL_CONF_DIR}/assets/presets/${PRESET_NAME}"
if [[ ! -d "$PRESET_DIR" ]]; then
  err "Preset directory not found: $PRESET_DIR"
fi

if [[ ! -d "$CONFIG_DIR" ]]; then
  err "Ambxst config directory not found: $CONFIG_DIR"
  err "Make sure Ambxst has been running and created its config."
fi

# ── Sync ──────────────────────────────────────────────────────────────────

info "Syncing Ambxst config → shell-conf preset"
info "  Config dir:  $CONFIG_DIR"
info "  Preset dir:  $PRESET_DIR"
info "  Excluded:    ${EXCLUDED_FILES[*]}"
echo ""

SYNCED=0
SKIPPED=0
UNCHANGED=0

for json_file in "$CONFIG_DIR"/*.json; do
  [[ -f "$json_file" ]] || continue
  filename="$(basename "$json_file")"

  # Skip excluded files
  if is_excluded "$filename"; then
    ((SKIPPED++))
    continue
  fi

  dest="${PRESET_DIR}/${filename}"
  src="${CONFIG_DIR}/${filename}"

  # Check if files are identical
  if [[ -f "$dest" ]] && diff -q "$src" "$dest" > /dev/null 2>&1; then
    ((UNCHANGED++))
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [SYNC]  $filename"
  else
    cp "$src" "$dest"
    info "  [SYNC]  $filename"
  fi
  ((SYNCED++))
done

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  info "Dry-run complete: $SYNCED to sync, $UNCHANGED unchanged, $SKIPPED excluded"
else
  info "Sync complete: $SYNCED files updated, $UNCHANGED unchanged, $SKIPPED excluded"
  if [[ "$SYNCED" -gt 0 ]]; then
    info ""
    info "Changes were made. To persist:"
    info "  cd $SHELL_CONF_DIR"
    info "  git add assets/presets/\"$PRESET_NAME\"/"
    info "  git commit -m 'Update Ambxst presets from user config'"
    info "  git push"
  fi
fi

exit 0
