#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Installation aborted at line ${LINENO}: ${BASH_COMMAND}" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ "${NIX_CONF_DEV_SHELL:-0}" != "1" ]; then
  command -v nix >/dev/null 2>&1 || {
    echo -e "${RED:-}The Nix command is required to enter the reproducible installer environment.${NC:-}" >&2
    exit 1
  }
  export NIX_CONF_DEV_SHELL=1
  exec nix develop "${SCRIPT_DIR}" --command bash "${SCRIPT_DIR}/install.sh" "$@"
fi

# Install script for nix-conf — clean installation from scratch.
# Selects a host, builds a nix-shell, applies the rebuild, and reboots.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== nix-conf — Installation Script ===${NC}"

# ─── Step 1: Select host ───────────────────────────────────────────────────
echo ""
echo "Available hosts:"
echo "  1) myMachine  — Desktop AMD + NVIDIA"
echo "  2) latitude   — Dell Latitude 5410 (Intel)"
echo ""
read -p "Select host [1-2]: " HOST_CHOICE

case "$HOST_CHOICE" in
  1) FLAKE_TARGET="myMachine" ;;
  2) FLAKE_TARGET="latitude" ;;
  *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
esac

echo -e "${GREEN}Selected: ${FLAKE_TARGET}${NC}"

configure_latitude_hardware() {
  echo -e "${YELLOW}Running robust hardware generation script...${NC}"
  "${SCRIPT_DIR}/scripts/generate-latitude-hardware.sh"
}

if [ "${FLAKE_TARGET}" = "latitude" ]; then
  echo -e "${YELLOW}Detecting Latitude storage...${NC}"
  configure_latitude_hardware
fi

# ─── Step 2: Ensure flake inputs are up to date ────────────────────────────
echo ""
echo -e "${YELLOW}Updating flake inputs...${NC}"
nix flake update

# ─── Step 3: Verify flake evaluates correctly ──────────────────────────────
echo ""
echo -e "${YELLOW}Checking flake...${NC}"
nix flake check --no-build

# ─── Step 4: Build and switch ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Building and switching to ${FLAKE_TARGET}...${NC}"
sudo nixos-rebuild switch --flake ".#${FLAKE_TARGET}" 2>&1 | tee /tmp/nixos-rebuild.log

# ─── Step 5: Reboot ───────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Rebuild successful!${NC}"
read -p "Reboot now? [y/N]: " REBOOT

case "$REBOOT" in
  y|Y|yes)
    echo -e "${YELLOW}Rebooting...${NC}"
    sudo reboot
    ;;
  *)
    echo "Reboot skipped. You can reboot manually when ready."
    ;;
esac
