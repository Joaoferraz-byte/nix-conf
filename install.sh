#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Installation aborted at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$SCRIPT_DIR"

if [ "${NIX_CONF_DEV_SHELL:-0}" != "1" ]; then
  command -v nix >/dev/null 2>&1 || {
    printf 'Error: the Nix command is required.\n' >&2
    exit 1
  }
  export NIX_CONF_DEV_SHELL=1
  exec nix develop "$SCRIPT_DIR" --command bash "$SCRIPT_DIR/install.sh" "$@"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HOST_CHOICE=""
REBOOT=""
if [ -n "${NIX_CONF_HOST:-}" ]; then
  FLAKE_TARGET="${NIX_CONF_HOST}"
elif [ "${NIX_CONF_NONINTERACTIVE:-0}" = "1" ]; then
  FLAKE_TARGET="${NIX_CONF_DEFAULT_HOST:-latitude}"
else
  printf '%b\n' "${GREEN}=== nix-conf installation ===${NC}"
  printf '\nAvailable hosts:\n'
  printf '  1) myMachine  - Desktop AMD + NVIDIA\n'
  printf '  2) latitude   - Dell Latitude 5410 (Intel)\n\n'
  read -r -p 'Select host [1-2]: ' HOST_CHOICE
  case "$HOST_CHOICE" in
    1) FLAKE_TARGET='myMachine' ;;
    2) FLAKE_TARGET='latitude' ;;
    *) printf '%b\n' "${RED}Invalid host selection.${NC}" >&2; exit 1 ;;
  esac
fi

case "$FLAKE_TARGET" in
  myMachine|my-machine|my_machine) FLAKE_TARGET='myMachine' ;;
  latitude) ;;
  *) printf '%b\n' "${RED}Unsupported host: $FLAKE_TARGET${NC}" >&2; exit 1 ;;
esac

printf '%b\n' "${GREEN}Repository: $SCRIPT_DIR${NC}"
printf '%b\n' "${GREEN}Selected host: $FLAKE_TARGET${NC}"

configure_hardware() {
  local status
  local -a target_args=()
  if [ -n "${NIXOS_TARGET_ROOT:-}" ]; then
    target_args=(--target-root "$NIXOS_TARGET_ROOT")
  fi
  printf '%b\n' "${YELLOW}Detecting and validating hardware for $FLAKE_TARGET...${NC}"
  if "$SCRIPT_DIR/scripts/generate-hardware.sh" --repo "$SCRIPT_DIR" --host "$FLAKE_TARGET" "${target_args[@]}"; then
    return 0
  else
    status=$?
  fi
  if [ "$FLAKE_TARGET" = 'latitude' ] && [ "${NIX_CONF_AUTO_DIAGNOSTIC:-1}" = '1' ] \
    && [ -x "$SCRIPT_DIR/scripts/collect-latitude-diagnostic.sh" ]; then
    printf '%b\n' "${YELLOW}Hardware detection failed; collecting a sanitized Latitude diagnostic...${NC}" >&2
    "$SCRIPT_DIR/scripts/collect-latitude-diagnostic.sh" --repo "$SCRIPT_DIR" \
      || printf '%b\n' "${YELLOW}Diagnostic collection failed; preserving the original hardware error.${NC}" >&2
  fi
  return "$status"
}

if configure_hardware; then
  :
else
  status=$?
  printf '%b\n' "${RED}Hardware detection failed. No rebuild was attempted.${NC}" >&2
  exit "$status"
fi

if [ "${NIX_CONF_UPDATE_FLAKE:-0}" = '1' ]; then
  printf '%b\n' "${YELLOW}Updating flake inputs by explicit request...${NC}"
  nix flake update
else
  printf '%b\n' "${GREEN}Using locked flake inputs. Set NIX_CONF_UPDATE_FLAKE=1 to update them.${NC}"
fi

printf '%b\n' "${YELLOW}Checking flake...${NC}"
nix flake check --no-build

REBUILD_LOG="${TMPDIR:-/tmp}/nixos-rebuild.log"
printf '%b\n' "${YELLOW}Building and switching to $FLAKE_TARGET...${NC}"
set +e
sudo nixos-rebuild switch --flake ".#$FLAKE_TARGET" 2>&1 | tee "$REBUILD_LOG"
REBUILD_STATUS="${PIPESTATUS[0]}"
set -e
if [ "$REBUILD_STATUS" -ne 0 ]; then
  printf '%b\n' "${RED}nixos-rebuild failed with exit code $REBUILD_STATUS.${NC}" >&2
  printf 'Full log: %s\n' "$REBUILD_LOG" >&2
  tail -n 80 "$REBUILD_LOG" >&2
  exit "$REBUILD_STATUS"
fi

printf '%b\n' "${GREEN}Rebuild successful.${NC}"
if [ "${NIX_CONF_NONINTERACTIVE:-0}" = '1' ]; then
  exit 0
fi
read -r -p 'Reboot now? [y/N]: ' REBOOT
case "$REBOOT" in
  y|Y|yes) sudo reboot ;;
  *) printf '%s\n' 'Reboot skipped.' ;;
esac
