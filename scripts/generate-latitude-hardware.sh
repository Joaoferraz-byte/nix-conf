#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HARDWARE_FILE="${REPO_ROOT}/modules/hosts/latitude/hardware.nix"

echo -e "${YELLOW}Generating hardware.nix for Latitude host...${NC}"

# Requisitos
command -v nixos-generate-config >/dev/null 2>&1 || {
  echo -e "${RED}nixos-generate-config is required. Are you on NixOS?${NC}"
  exit 1
}

# Criar um diretório temporário para gerar a configuração
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# O target_root é o ponto de montagem da instalação. A raiz padrão é `/`.
# O nixos-generate-config rejeita a forma explícita `--root /` em versões
# recentes, portanto só passamos --root quando o alvo não é a raiz padrão.
TARGET_ROOT="${NIXOS_INSTALL_ROOT:-/}"
if [ ! -d "$TARGET_ROOT" ]; then
  echo -e "${RED}Target root does not exist or is not a directory: $TARGET_ROOT${NC}" >&2
  exit 1
fi

echo "Target root: $TARGET_ROOT"

# Gerar configuração de hardware
echo "Running nixos-generate-config..."
# --show-hardware-config imprime a configuração em stdout; --dir não é usado
# nesse modo. Capturamos stderr separadamente para não ocultar o erro real.
GEN_CONFIG_CMD=(nixos-generate-config --show-hardware-config)
if [ "$TARGET_ROOT" != "/" ]; then
  GEN_CONFIG_CMD+=(--root "$TARGET_ROOT")
fi

FILESYSTEMS_FROM_GENERATOR=true
if ! "${GEN_CONFIG_CMD[@]}" \
    > "$TMP_DIR/hardware-configuration.nix" \
    2> "$TMP_DIR/nixos-generate-config.stderr"; then
  # O nixos-generate-config aborta inteiro quando não consegue executar
  # `btrfs subvolume show` para uma montagem. Isso é conhecido em sistemas
  # com bind mounts, layouts Btrfs especiais e alguns btrfs-progs recentes.
  if grep -qiE "subvolume info|subvolume|btrfs" "$TMP_DIR/nixos-generate-config.stderr"; then
    echo -e "${YELLOW}Btrfs filesystem detection failed; retrying hardware-only generation (--no-filesystems).${NC}" >&2
    FILESYSTEMS_FROM_GENERATOR=false
    FALLBACK_CMD=("${GEN_CONFIG_CMD[@]}" --no-filesystems)
    if ! "${FALLBACK_CMD[@]}" \
        > "$TMP_DIR/hardware-configuration.nix" \
        2> "$TMP_DIR/nixos-generate-config-fallback.stderr"; then
      echo -e "${RED}Failed to generate hardware configuration even with --no-filesystems.${NC}" >&2
      cat "$TMP_DIR/nixos-generate-config.stderr" >&2
      cat "$TMP_DIR/nixos-generate-config-fallback.stderr" >&2
      exit 1
    fi
  else
    echo -e "${RED}Failed to generate hardware configuration.${NC}" >&2
    cat "$TMP_DIR/nixos-generate-config.stderr" >&2
    exit 1
  fi
fi

if [ ! -s "$TMP_DIR/hardware-configuration.nix" ]; then
  echo -e "${RED}nixos-generate-config completed without producing hardware configuration.${NC}" >&2
  exit 1
fi

# Extrair as partes importantes com mais robustez
echo "Parsing generated hardware configuration..."

# 1. Imports e módulos do kernel
INITRD_AVAILABLE=$(grep -m1 "boot\.initrd\.availableKernelModules" "$TMP_DIR/hardware-configuration.nix" || echo 'boot.initrd.availableKernelModules = [ ];')
INITRD_KERNEL=$(grep -m1 "boot\.initrd\.kernelModules" "$TMP_DIR/hardware-configuration.nix" || echo 'boot.initrd.kernelModules = [ ];')
KERNEL_MODULES=$(grep -m1 "boot\.kernelModules" "$TMP_DIR/hardware-configuration.nix" || echo 'boot.kernelModules = [ ];')
EXTRA_MODULES=$(grep -m1 "boot\.extraModulePackages" "$TMP_DIR/hardware-configuration.nix" || echo 'boot.extraModulePackages = [ ];')

# 2. FileSystems e Swap
# Em layouts Btrfs problemáticos, o gerador pode detectar o hardware, mas
# não consegue emitir fileSystems. Nesse caso, nunca inventamos UUIDs ou
# subvolumes: preservamos o bloco já existente no hardware.nix.
if [ "$FILESYSTEMS_FROM_GENERATOR" = true ]; then
  FS_AND_SWAP=$(awk '/fileSystems\."\/" =/,/nixpkgs\.hostPlatform/' "$TMP_DIR/hardware-configuration.nix" | grep -v "nixpkgs.hostPlatform" | sed '/^$/d')
else
  FS_AND_SWAP=$(awk '/^[[:space:]]*fileSystems\."/ { found=1 } found { print } /^[[:space:]]*swapDevices[[:space:]]*=/ { exit }' "$HARDWARE_FILE")
  if [ -z "$FS_AND_SWAP" ]; then
    echo -e "${RED}Btrfs detection failed and no existing fileSystems block is available; refusing to invent mounts.${NC}" >&2
    exit 1
  fi
  echo -e "${YELLOW}Preserving existing fileSystems/swapDevices block because the Btrfs scanner failed.${NC}" >&2
fi

if [ -z "$FS_AND_SWAP" ]; then
  echo -e "${RED}No filesystem configuration was produced; refusing to write an incomplete hardware.nix.${NC}" >&2
  exit 1
fi

# 3. Plataforma e CPU
HOST_PLATFORM=$(grep -m1 "nixpkgs\.hostPlatform" "$TMP_DIR/hardware-configuration.nix" || echo 'nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";')
CPU_MICROCODE=$(grep -m1 "hardware\.cpu\..*\.updateMicrocode" "$TMP_DIR/hardware-configuration.nix" || echo 'hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;')

# Escrever o novo hardware.nix
cat > "$HARDWARE_FILE" <<INNER_EOF
# Do not modify this file!  It was generated by generate-latitude-hardware.sh
# and may be overwritten by future invocations.
{ config, lib, pkgs, modulesPath, ... }:

{
  flake.nixosModules.latitudeHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    $INITRD_AVAILABLE
    $INITRD_KERNEL
    $KERNEL_MODULES
    $EXTRA_MODULES

$FS_AND_SWAP

    $HOST_PLATFORM
    $CPU_MICROCODE

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
INNER_EOF

echo -e "${GREEN}Successfully generated ${HARDWARE_FILE}${NC}"
