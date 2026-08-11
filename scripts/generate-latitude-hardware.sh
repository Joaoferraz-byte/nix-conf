#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HARDWARE_FILE="${REPO_ROOT}/modules/hosts/latitude/hardware.nix"
GENERATED_FILE="${REPO_ROOT}/modules/hosts/latitude/hardware-configuration.generated.nix"
SOURCE_FILE="${NIXOS_HARDWARE_CONFIG_SOURCE:-/etc/nixos/hardware-configuration.nix}"

fail() {
  echo -e "${RED}Error: $*${NC}" >&2
  exit 1
}

backup_file() {
  local file="$1"
  if [ -e "$file" ]; then
    local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
    cp --preserve=mode,timestamps "$file" "$backup"
    echo -e "${YELLOW}Backup created: ${backup}${NC}"
  fi
}

echo -e "${YELLOW}Generating Latitude hardware module from ${SOURCE_FILE}...${NC}"

[ -r "$SOURCE_FILE" ] || fail "Cannot read ${SOURCE_FILE}. Boot the installed NixOS system or set NIXOS_HARDWARE_CONFIG_SOURCE to a readable hardware-configuration.nix."
[ -s "$SOURCE_FILE" ] || fail "Source hardware configuration is empty: ${SOURCE_FILE}"

grep -q 'fileSystems\.' "$SOURCE_FILE" || fail "The source does not contain fileSystems entries: ${SOURCE_FILE}"
if grep -qE 'BOOT-PARTUUID|PARTUUID([-_]?(HERE|TODO|CHANGE_ME))|UUID=CHANGE_ME|/dev/disk/by-label/(nixos|CHANGE_ME)' "$SOURCE_FILE"; then
  fail "The source contains a placeholder device identifier. Fix /etc/nixos/hardware-configuration.nix before copying it."
fi

mkdir -p "$(dirname "$HARDWARE_FILE")"
backup_file "$HARDWARE_FILE"
backup_file "$GENERATED_FILE"

# Keep the distribution-generated module as a separate file. This avoids
# trying to parse nested Nix braces with sed/awk and preserves every mount,
# initrd module, filesystem option, swap entry, and import exactly as generated.
install -m 0644 "$SOURCE_FILE" "$GENERATED_FILE"

cat > "$HARDWARE_FILE" <<'NIX_EOF'
{ ... }:
{
  # The generated file is a normal NixOS module produced by
  # nixos-generate-config. It is imported; its contents are not spliced
  # into this file and no braces are parsed by the shell script.
  flake.nixosModules.latitudeHardware = { ... }:
    {
      imports = [ ./hardware-configuration.generated.nix ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
}
NIX_EOF

# Basic structural checks. Full evaluation is optional because this script may
# run from a minimal terminal before all flake inputs are available.
grep -q 'hardware-configuration.generated.nix' "$HARDWARE_FILE" || fail "Generated wrapper is incomplete."
grep -q 'fileSystems\.' "$GENERATED_FILE" || fail "Copied source lost its fileSystems entries."

if command -v nix-instantiate >/dev/null 2>&1; then
  nix-instantiate --parse "$GENERATED_FILE" >/dev/null \
    || fail "Nix parser rejected the copied hardware configuration."
  nix-instantiate --parse "$HARDWARE_FILE" >/dev/null \
    || fail "Nix parser rejected the generated wrapper."
fi

echo -e "${GREEN}Successfully generated:${NC}"
echo "  wrapper: $HARDWARE_FILE"
echo "  source copy: $GENERATED_FILE"
echo -e "${GREEN}No nixos-generate-config scan was required.${NC}"
