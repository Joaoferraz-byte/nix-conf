#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="${NIX_CONF_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
TARGET_ROOT="${NIXOS_TARGET_ROOT:-}"
SOURCE_OVERRIDE="${NIXOS_HARDWARE_CONFIG_SOURCE:-}"
HOST_NAME="${NIX_CONF_HOST:-}"
ESP_DEVICE="${NIXOS_ESP_DEVICE:-}"
DRY_RUN=0

TEMP_DIR="$(mktemp -d)"
TEMP_FILE="${TEMP_DIR}/hardware-configuration.nix"
GENERATOR_LOG="${TEMP_DIR}/nixos-generate-config.log"

HOST_SLUG=""
HOST_DIR=""
ENTRYPOINT_FILE=""
HARDWARE_FILE=""
BACKUP_ROOT=""
SOURCE_LABEL=""
ROOT_SOURCE=""
ROOT_FSTYPE=""
BOOT_DIR=""
INITRD_MODULES=()

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: generate-hardware.sh --host HOST [options]

Hosts:
  latitude     Dell Latitude host
  myMachine    Desktop host

Options:
  --host NAME          Host whose tracked hardware file will be generated.
  --repo PATH          Repository containing modules/hosts.
  --target-root PATH  Mounted installed root. If omitted, detect it.
  --esp DEVICE         Existing EFI System Partition. If omitted, detect it.
  --source PATH        Explicit hardware-configuration.nix source.
  --dry-run            Print detected topology without writing or mounting.
  --help               Show this help.

The script never formats, partitions, changes firmware, or adds ACPI parameters.
It uses nixos-generate-config when possible and a mount-table fallback for
filesystem layouts that the official generator cannot inspect.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      [ "$#" -ge 2 ] || fail "$1 requires a host name."
      HOST_NAME="$2"
      shift 2
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
    --esp|--boot-device)
      [ "$#" -ge 2 ] || fail "$1 requires a device."
      ESP_DEVICE="$2"
      shift 2
      ;;
    --source)
      [ "$#" -ge 2 ] || fail "$1 requires a path."
      SOURCE_OVERRIDE="$2"
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

normalize_host() {
  local normalized
  normalized="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]_-')"
  case "$normalized" in
    latitude|latitude5410|delllatitude|delllatitude5410)
      printf 'latitude\n'
      ;;
    mymachine|desktop|desktopamdnvidia)
      printf 'my-machine\n'
      ;;
    *)
      return 1
      ;;
  esac
}

if ! HOST_SLUG="$(normalize_host "$HOST_NAME")"; then
  fail "Unsupported host '$HOST_NAME'. Use --host latitude or --host myMachine."
fi

case "$HOST_SLUG" in
  latitude)
    HOST_NAME="latitude"
    ;;
  my-machine)
    HOST_NAME="myMachine"
    ;;
esac

command -v findmnt >/dev/null 2>&1 || fail "findmnt is required."
command -v lsblk >/dev/null 2>&1 || fail "lsblk is required."
command -v realpath >/dev/null 2>&1 || fail "realpath is required."
command -v mount >/dev/null 2>&1 || fail "mount is required."

if [ "$(id -u)" -eq 0 ]; then
  if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    exec sudo -u "${SUDO_USER}" -H -- "$0" "$@"
  fi
  fail "Run this script as the user who owns the Git checkout; it uses sudo only for privileged mount operations."
fi

command -v sudo >/dev/null 2>&1 || fail "sudo is required when an existing ESP must be mounted."

REPO_ROOT="$(realpath -e "$REPO_ROOT")" || fail "Repository path does not exist: $REPO_ROOT"
HOST_DIR="${REPO_ROOT}/modules/hosts/${HOST_SLUG}"
ENTRYPOINT_FILE="${HOST_DIR}/hardware.nix"
HARDWARE_FILE="${HOST_DIR}/hardware-configuration.nix"
BACKUP_ROOT="${NIX_CONF_HARDWARE_BACKUP_DIR:-${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/nix-conf/hardware-backups/${HOST_SLUG}}"

[ -r "$ENTRYPOINT_FILE" ] || fail "Missing hardware entrypoint: $ENTRYPOINT_FILE"
[ -r "$HARDWARE_FILE" ] || fail "Missing tracked hardware file: $HARDWARE_FILE"
grep -q 'hardware-configuration.nix' "$ENTRYPOINT_FILE" \
  || fail "Hardware entrypoint does not import hardware-configuration.nix: $ENTRYPOINT_FILE"

if command -v udevadm >/dev/null 2>&1; then
  udevadm settle || true
fi

printf '%s\n' 'Detected block-device inventory:'
lsblk --list --paths --output NAME,TYPE,FSTYPE,PARTTYPE,PARTLABEL,LABEL,UUID,PARTUUID,MOUNTPOINTS

is_mounted_target() {
  findmnt -rn -M "$1" -o SOURCE,FSTYPE >/dev/null 2>&1
}

is_valid_nixos_root() {
  local path="$1"
  local source fstype
  [ -d "$path/etc" ] || return 1
  source="$(findmnt -rn -M "$path" -o SOURCE 2>/dev/null || true)"
  fstype="$(findmnt -rn -M "$path" -o FSTYPE 2>/dev/null || true)"
  [ -n "$source" ] || return 1
  case "$fstype" in
    overlay|squashfs|iso9660|tmpfs) return 1 ;;
  esac
  [ -e "$path/etc/NIXOS" ] || [ -d "$path/nix/store" ] || [ -d "$path/etc/nixos" ] || return 1
}

discover_target_root() {
  local candidate
  local -a candidates=()
  for candidate in / /mnt /target /mnt/nixos /media/nixos; do
    [ -d "$candidate" ] || continue
    is_valid_nixos_root "$candidate" && candidates+=("$candidate")
  done
  case "${#candidates[@]}" in
    0) fail "No mounted NixOS root was detected. Use --target-root after mounting the installed system." ;;
    1) TARGET_ROOT="${candidates[0]}" ;;
    *)
      printf 'Candidate NixOS roots:\n' >&2
      printf '  %s\n' "${candidates[@]}" >&2
      fail "More than one NixOS root was detected; use --target-root explicitly."
      ;;
  esac
}

require_target_root() {
  local source fstype
  [ -d "$TARGET_ROOT/etc" ] || fail "Target root has no etc directory: $TARGET_ROOT"
  source="$(findmnt -rn -M "$TARGET_ROOT" -o SOURCE 2>/dev/null || true)"
  fstype="$(findmnt -rn -M "$TARGET_ROOT" -o FSTYPE 2>/dev/null || true)"
  [ -n "$source" ] || fail "Target root is not mounted: $TARGET_ROOT"
  case "$fstype" in
    overlay|squashfs|iso9660|tmpfs) fail "Target root is a temporary or Live ISO filesystem: $TARGET_ROOT ($fstype)" ;;
    ext4|btrfs) ;;
    *) fail "Unsupported target root filesystem: $fstype. Only ext4 and btrfs are supported." ;;
  esac
  ROOT_SOURCE="${source%%[*}"
  ROOT_FSTYPE="$fstype"
  printf 'Target root: %s (%s, %s)\n' "$TARGET_ROOT" "$ROOT_SOURCE" "$ROOT_FSTYPE"
  printf 'Filesystem family: %s\n' "$ROOT_FSTYPE"
}

validate_esp_device() {
  local device="$1"
  local type fstype parttype
  [ -b "$device" ] || fail "ESP is not a block device: $device"
  read -r type fstype parttype < <(lsblk --noheadings --raw --output TYPE,FSTYPE,PARTTYPE "$device")
  [ "$type" = "part" ] || fail "ESP path is not a partition: $device"
  [ "$fstype" = "vfat" ] || fail "ESP is not vfat: $device ($fstype)"
  [ "${parttype,,}" = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ] \
    || fail "Partition is not an EFI System Partition: $device ($parttype)"
}

discover_esp() {
  local path type fstype parttype
  local -a candidates=()
  while read -r path type fstype parttype; do
    [ "$type" = "part" ] || continue
    [ "$fstype" = "vfat" ] || continue
    [ "${parttype,,}" = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ] || continue
    if findmnt -rn -S "$path" -o TARGET 2>/dev/null | grep -Fxq "$BOOT_DIR"; then
      ESP_DEVICE="$path"
      return 0
    fi
    candidates+=("$path")
  done < <(lsblk --paths --noheadings --raw --output NAME,TYPE,FSTYPE,PARTTYPE)
  case "${#candidates[@]}" in
    0) fail "No EFI System Partition was detected. Mount the existing ESP or use --esp DEVICE." ;;
    1) ESP_DEVICE="${candidates[0]}" ;;
    *)
      printf 'Candidate EFI System Partitions:\n' >&2
      printf '  %s\n' "${candidates[@]}" >&2
      fail "More than one ESP was detected; use --esp DEVICE explicitly."
      ;;
  esac
}

ensure_boot_mount() {
  BOOT_DIR="${TARGET_ROOT%/}/boot"
  [ -d "$BOOT_DIR" ] || fail "Boot directory does not exist: $BOOT_DIR"
  if is_mounted_target "$BOOT_DIR"; then
    printf 'Existing boot mount: '
    findmnt -rn -M "$BOOT_DIR" -o SOURCE,FSTYPE,TARGET
    return 0
  fi
  [ "$DRY_RUN" -eq 1 ] && {
    [ -n "$ESP_DEVICE" ] || discover_esp
    validate_esp_device "$ESP_DEVICE"
    printf 'Would mount existing ESP %s at %s\n' "$ESP_DEVICE" "$BOOT_DIR"
    return 0
  }
  [ -n "$ESP_DEVICE" ] || discover_esp
  validate_esp_device "$ESP_DEVICE"
  sudo -- mount "$ESP_DEVICE" "$BOOT_DIR"
  printf 'Mounted existing ESP: '
  findmnt -rn -M "$BOOT_DIR" -o SOURCE,FSTYPE,TARGET
}

mount_records() {
  findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS \
    | awk -v root="$TARGET_ROOT" 'BEGIN { FS="[[:space:]]+"; OFS="\t"; prefix=(root == "/" ? "/" : root "/") } $1 == root || index($1, prefix) == 1 { print $1, $2, $3, $4 }'
}

relative_mountpoint() {
  local mountpoint="$1"
  if [ "$TARGET_ROOT" = "/" ]; then
    printf '%s\n' "$mountpoint"
  elif [ "$mountpoint" = "$TARGET_ROOT" ]; then
    printf '/\n'
  else
    printf '%s\n' "${mountpoint#${TARGET_ROOT}}"
  fi
}

print_detected_mounts() {
  local mountpoint source fstype options relative
  printf '%s\n' 'Detected filesystem mapping:'
  while IFS=$'\t' read -r mountpoint source fstype options; do
    [ -n "$mountpoint" ] || continue
    relative="$(relative_mountpoint "$mountpoint")"
    source="${source%%[*}"
    printf '  %s <- %s (%s) [%s]\n' "$relative" "$source" "$fstype" "$options"
  done < <(mount_records)
}

stable_device_path() {
  local source="$1"
  local resolved link
  source="${source%%[*}"
  [ -e "$source" ] || { printf '%s\n' "$source"; return 0; }
  resolved="$(readlink -f -- "$source" 2>/dev/null || true)"
  [ -n "$resolved" ] || { printf '%s\n' "$source"; return 0; }
  for link in /dev/disk/by-uuid/* /dev/disk/by-partuuid/*; do
    [ -e "$link" ] || continue
    if [ "$(readlink -f -- "$link" 2>/dev/null || true)" = "$resolved" ]; then
      printf '%s\n' "$link"
      return 0
    fi
  done
  printf '%s\n' "$source"
}

append_unique() {
  local value="$1"
  local item
  for item in "${INITRD_MODULES[@]}"; do
    [ "$item" = "$value" ] && return 0
  done
  INITRD_MODULES+=("$value")
}

collect_initrd_modules() {
  local device type base module_path driver
  INITRD_MODULES=()
  while read -r device type; do
    [ "$type" = "disk" ] || [ "$type" = "part" ] || continue
    base="$(basename "$device")"
    module_path="$(readlink -f "/sys/class/block/$base/device/driver/module" 2>/dev/null || true)"
    if [ -n "$module_path" ]; then
      driver="$(basename "$module_path")"
      [ -n "$driver" ] && append_unique "$driver"
    fi
    case "$base" in
      nvme*) append_unique nvme ;;
      mmcblk*) append_unique mmc_block ;;
      sd*) append_unique sd_mod ;;
    esac
  done < <(lsblk --noheadings --raw --paths --output NAME,TYPE 2>/dev/null || true)
  append_unique "$ROOT_FSTYPE"
  append_unique vfat
  for module in usbhid usb_storage xhci_pci; do
    if grep -q "^${module} " /proc/modules 2>/dev/null; then
      append_unique "$module"
    fi
  done
}

btrfs_subvolume_options() {
  local options="$1"
  local option
  IFS=',' read -r -a option_list <<< "$options"
  for option in "${option_list[@]}"; do
    case "$option" in
      subvol=*|subvolid=*) printf '%s\n' "$option" ;;
    esac
  done
}

write_mount_table_config() {
  local mountpoint source fstype options relative stable subvol_option
  local swap_source swap_stable
  local -a seen_mountpoints=()
  collect_initrd_modules
  {
    printf '# Generated from the mounted target topology by generate-hardware.sh.\n'
    printf '{ config, lib, pkgs, modulesPath, ... }:\n\n{\n'
    printf '  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];\n\n'
    printf '  boot.initrd.availableKernelModules = [\n'
    printf '    "%s"\n' "${INITRD_MODULES[@]}"
    printf '  ];\n  boot.initrd.kernelModules = [ "%s" ];\n  boot.extraModulePackages = [ ];\n' "$ROOT_FSTYPE"
    if [ "$ROOT_FSTYPE" = "btrfs" ]; then
      printf '  boot.supportedFilesystems = [ "btrfs" ];\n'
    fi
    printf '\n'
  } > "$TEMP_FILE"

  while IFS=$'\t' read -r mountpoint source fstype options; do
    [ -n "$mountpoint" ] || continue
    relative="$(relative_mountpoint "$mountpoint")"
    [ "$relative" = "/nix/store" ] && continue
    case " ${seen_mountpoints[*]} " in *" $relative "*) continue ;; esac
    case "$fstype" in
      btrfs|vfat|ext2|ext3|ext4|xfs|f2fs|zfs|ntfs|ntfs3) ;;
      *) continue ;;
    esac
    source="${source%%[*}"
    [ -n "$source" ] || continue
    stable="$(stable_device_path "$source")"
    [ -n "$stable" ] || continue
    seen_mountpoints+=("$relative")
    printf '  fileSystems."%s" = {\n' "$relative" >> "$TEMP_FILE"
    printf '    device = "%s";\n    fsType = "%s";\n' "$stable" "$fstype" >> "$TEMP_FILE"
    if [ "$fstype" = "btrfs" ]; then
      while IFS= read -r subvol_option; do
        [ -n "$subvol_option" ] || continue
        printf '    options = [ "%s" ];\n' "$subvol_option" >> "$TEMP_FILE"
      done < <(btrfs_subvolume_options "$options")
    fi
    printf '  };\n' >> "$TEMP_FILE"
  done < <(mount_records)

  {
    printf '\n  swapDevices = [\n'
    while read -r swap_source _; do
      [ -n "$swap_source" ] || continue
      [ -e "$swap_source" ] || continue
      swap_stable="$(stable_device_path "$swap_source")"
      printf '    { device = "%s"; }\n' "$swap_stable"
    done < <(awk 'NR > 1 { print $1, $2 }' /proc/swaps)
    printf '  ];\n\n  networking.useDHCP = lib.mkDefault true;\n  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";\n}\n'
  } >> "$TEMP_FILE"
}

is_filesystem_probe_failure() {
  grep -qiE 'failed to retrieve subvolume info|btrfs[[:space:]]+subvol|btrfs.*subvolume|cannot retrieve filesystem information' "$GENERATOR_LOG"
}

find_fallback_source() {
  local candidate
  for candidate in \
    "$TARGET_ROOT/etc/nixos/hardware-configuration.nix" \
    "$TARGET_ROOT/etc/nixos/hardware.nix"; do
    if [ -r "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

copy_hardware_source() {
  local source="$1"
  [ -r "$source" ] || fail "Hardware source is not readable: $source"
  cp -- "$source" "$TEMP_FILE"
}

validate_device_references() {
  local device
  local -a devices
  mapfile -t devices < <(sed -nE 's/.*(^|[[:space:]]|\{)device[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*;.*/\2/p' "$TEMP_FILE")
  [ "${#devices[@]}" -gt 0 ] || fail "Generated hardware configuration contains no device references: $SOURCE_LABEL"
  for device in "${devices[@]}"; do
    case "$device" in
      /dev/*) [ -e "$device" ] || fail "Generated device does not exist in the current environment: $device" ;;
    esac
  done
}

validate_generated_config() {
  [ -s "$TEMP_FILE" ] || fail "Detected hardware configuration is empty: $SOURCE_LABEL"
  grep -qE 'fileSystems\."/' "$TEMP_FILE" || fail "Detected hardware configuration contains no fileSystems entries: $SOURCE_LABEL"
  grep -q 'fileSystems."/"' "$TEMP_FILE" || fail "Detected hardware configuration has no root filesystem entry: $SOURCE_LABEL"
  grep -qE 'BOOT-PARTUUID|CHANGE_ME|TODO|PLACEHOLDER|PARTUUID_HERE|UUID_HERE|ROOT-PARTUUID' "$TEMP_FILE" \
    && fail "Detected hardware configuration contains a placeholder device identifier: $SOURCE_LABEL"
  validate_device_references
  if command -v nix-instantiate >/dev/null 2>&1; then
    local parse_error="${TEMP_DIR}/nix-parse-error"
    if ! nix-instantiate --parse "$TEMP_FILE" >/dev/null 2> "$parse_error"; then
      if grep -qE 'daemon-socket.*Permission denied|getting status of /nix/var/nix' "$parse_error"; then
        printf 'Warning: skipped Nix parser check because the local daemon is unavailable.\n' >&2
      else
        cat "$parse_error" >&2
        fail "Nix parser rejected the detected hardware configuration."
      fi
    fi
  fi
}

backup_file() {
  local source="$1"
  if [ -e "$source" ]; then
    mkdir -p "$BACKUP_ROOT"
    install -m 0644 "$source" "$BACKUP_ROOT/$(basename "$source").$(date +%Y%m%d-%H%M%S)"
  fi
}

[ -n "$TARGET_ROOT" ] || discover_target_root
TARGET_ROOT="$(realpath -e "$TARGET_ROOT")" || fail "Target root does not exist: $TARGET_ROOT"
require_target_root
ensure_boot_mount
print_detected_mounts
[ "$DRY_RUN" -eq 1 ] && exit 0

[ -w "$HOST_DIR" ] || fail "Hardware host directory is not writable: $HOST_DIR"

if [ "${NIX_CONF_ALLOW_HARDWARE_REPLACE:-0}" != "1" ] \
  && { ! git -C "$REPO_ROOT" diff --quiet -- "$HARDWARE_FILE" \
    || ! git -C "$REPO_ROOT" diff --cached --quiet -- "$HARDWARE_FILE"; }; then
  printf 'Tracked hardware file has local changes; validating and reusing it without replacement: %s\n' "$HARDWARE_FILE"
  cp -- "$HARDWARE_FILE" "$TEMP_FILE"
  SOURCE_LABEL="$HARDWARE_FILE (reused local configuration)"
  validate_generated_config
  printf 'Reused and validated: %s\n' "$HARDWARE_FILE"
  printf 'Source: %s\n' "$SOURCE_LABEL"
  exit 0
fi

if [ -n "$SOURCE_OVERRIDE" ]; then
  SOURCE_OVERRIDE="$(realpath -e "$SOURCE_OVERRIDE")" || fail "Hardware source does not exist: $SOURCE_OVERRIDE"
  copy_hardware_source "$SOURCE_OVERRIDE"
  SOURCE_LABEL="$SOURCE_OVERRIDE"
elif command -v nixos-generate-config >/dev/null 2>&1; then
  printf 'Detecting hardware for %s with nixos-generate-config under %s...\n' "$HOST_NAME" "$TARGET_ROOT"
  if [ "$TARGET_ROOT" = "/" ]; then
    if nixos-generate-config --show-hardware-config > "$TEMP_FILE" 2> "$GENERATOR_LOG"; then
      SOURCE_LABEL="nixos-generate-config --show-hardware-config"
    else
      cat "$GENERATOR_LOG" >&2
      if is_filesystem_probe_failure; then
        printf 'The official generator could not inspect the filesystem; using the mounted-topology fallback.\n' >&2
        write_mount_table_config
        SOURCE_LABEL="mounted-topology fallback"
      else
        SOURCE_FILE="$(find_fallback_source || true)"
        [ -n "$SOURCE_FILE" ] || fail "Hardware detection failed and no conventional hardware file exists under the target root."
        copy_hardware_source "$SOURCE_FILE"
        SOURCE_LABEL="$SOURCE_FILE"
      fi
    fi
  elif nixos-generate-config --root "$TARGET_ROOT" --show-hardware-config > "$TEMP_FILE" 2> "$GENERATOR_LOG"; then
    SOURCE_LABEL="nixos-generate-config --root $TARGET_ROOT --show-hardware-config"
  else
    cat "$GENERATOR_LOG" >&2
    if is_filesystem_probe_failure; then
      printf 'The official generator could not inspect the filesystem; using the mounted-topology fallback.\n' >&2
      write_mount_table_config
      SOURCE_LABEL="mounted-topology fallback"
    else
      SOURCE_FILE="$(find_fallback_source || true)"
      [ -n "$SOURCE_FILE" ] || fail "Hardware detection failed and no conventional hardware file exists under the target root."
      copy_hardware_source "$SOURCE_FILE"
      SOURCE_LABEL="$SOURCE_FILE"
    fi
  fi
else
  SOURCE_FILE="$(find_fallback_source || true)"
  [ -n "$SOURCE_FILE" ] || fail "Install nixos-install-tools or set --source to a valid hardware file."
  copy_hardware_source "$SOURCE_FILE"
  SOURCE_LABEL="$SOURCE_FILE"
fi

validate_generated_config
backup_file "$HARDWARE_FILE"
install -m 0644 "$TEMP_FILE" "$HARDWARE_FILE"
git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || fail "Repository root is not a Git worktree: $REPO_ROOT"
git -C "$REPO_ROOT" add -- "$HARDWARE_FILE"
git -C "$REPO_ROOT" diff --cached --check -- "$HARDWARE_FILE"
printf 'Generated and staged: %s\n' "$HARDWARE_FILE"
printf 'Source: %s\n' "$SOURCE_LABEL"
printf 'Backup directory: %s\n' "$BACKUP_ROOT"
printf 'Review with: git -C %s diff --cached -- %s\n' "$REPO_ROOT" "${HARDWARE_FILE#${REPO_ROOT}/}"
