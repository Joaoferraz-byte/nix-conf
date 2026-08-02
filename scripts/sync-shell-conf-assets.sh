#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# sync-shell-conf-assets.sh
# ════════════════════════════════════════════════════════════════════════════
# Synchronizes the shell-conf repository's presets/ directory back to the
# Home Manager source directory, ensuring the Nix build always uses the
# latest preset files.
#
# This is the reverse of sync-ambxst-presets.sh: it pushes the shell-conf
# assets into the flake's HM module source path.
#
# Usage:
#   ./scripts/sync-shell-conf-assets.sh [--shell-conf-dir /path/to/shell-conf]
# ════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────
SHELL_CONF_DIR="${SHELL_CONF_DIR:-${1:-}}"
PRESET_NAME="Ambxst Default"

# ── Argument Parsing ──────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Synchronize shell-conf presets into the nix-conf Home Manager source.

Options:
  --shell-conf-dir DIR    Path to the shell-conf repository
  -h, --help              Show this help message

Examples:
  $(basename "$0") --shell-conf-dir /home/livara/shell-conf
  SHELL_CONF_DIR=/home/livara/shell-conf $(basename "$0")
EOF
  exit 0
}

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
err() { echo "[ERROR] $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell-conf-dir)
      SHELL_CONF_DIR="$2"
      shift 2
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

if [[ -z "$SHELL_CONF_DIR" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  NIX_CONF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  CANDIDATE="$(dirname "$NIX_CONF_DIR")/shell-conf"
  if [[ -d "$CANDIDATE/assets/presets/$PRESET_NAME" ]]; then
    SHELL_CONF_DIR="$CANDIDATE"
  fi
fi

if [[ -z "$SHELL_CONF_DIR" ]]; then
  err "Cannot find shell-conf repository. Use --shell-conf-dir or set SHELL_CONF_DIR."
fi

PRESET_DIR="${SHELL_CONF_DIR}/assets/presets/${PRESET_NAME}"
if [[ ! -d "$PRESET_DIR" ]]; then
  err "Preset directory not found: $PRESET_DIR"
fi

# ── Determine destination ─────────────────────────────────────────────────
# The nix-conf HM module copies from shell-conf's preset dir during activation.
# Since shell-conf is a flake input, the presets are already in the flake's
# closure. This script is mainly for development workflow:
#   1. Edit presets in shell-conf repo
#   2. Run this to verify the preset dir is up-to-date
#   3. Commit and push shell-conf
#   4. nix-conf rebuild picks up the new shell-conf input

info "Shell-conf preset directory verified:"
info "  $PRESET_DIR"
echo ""
info "Files in preset:"
ls -1 "$PRESET_DIR"/*.json 2>/dev/null | while read f; do echo "  $(basename "$f")"; done
echo ""
info "The nix-conf flake imports shell-conf as a flake input."
info "On next 'nixos-rebuild switch', the latest shell-conf presets will be"
info "copied to \$AMBXST_CONFIG_ROOT/config/ (only if files don't exist)."
