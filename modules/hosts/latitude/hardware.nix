# ─── Latitude Hardware ──────────────────────────────────────────
# Hardware gerado pelo nixos-generate-config.
#
# ══════════════════════════════════════════════════════════════════
# ATENÇÃO: ESTE HOST AINDA NÃO ESTÁ FUNCIONAL
# ══════════════════════════════════════════════════════════════════
# Os UUIDs de disco abaixo são PLACEHOLDERS e devem ser substituídos
# pelos valores reais da máquina após rodar `nixos-generate-config`.
#
# Para gerar os valores corretos:
#   1. Boot a partir do ISO NixOS no Dell Latitude
#   2. Particione e monte os discos em /mnt
#   3. nixos-generate-config --root /mnt
#   4. Copie os UUIDs de /mnt/etc/nixos/hardware-configuration.nix
#      para este arquivo, substituindo todos os REPLACE_*_UUID abaixo.
#   5. Rode: sudo nixos-rebuild switch --flake .#latitude
#
# Enquanto os UUIDs não forem substituídos, o build do host latitude
# vai FALHAR ao tentar montar os filesystems (UUID inexistente).
# O host myMachine (limine) não é afetado por este arquivo.
# ══════════════════════════════════════════════════════════════════
{ ... }: {
  flake.nixosModules.latitudeHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    # ── Módulos do kernel (initrd) ────────────────────────────────────────
    # Latitude: xhci_pci, ahci, nvme, usb_storage, usbhid, sd_mod
    # A GPU integrada Intel UHD também precisa de i915 em estágios iniciais.
    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];

    # ── Filesystems ───────────────────────────────────────────────────────
    # TODO: substitua os UUIDs pelos valores reais da máquina.
    # Execute `lsblk -f` ou `blkid` no live ISO para obter os UUIDs corretos.
    fileSystems."/" =
      { device = "/dev/disk/by-uuid/REPLACE_ROOT_UUID";
        fsType = "btrfs";
      };

    fileSystems."/home" =
      { device = "/dev/disk/by-uuid/REPLACE_HOME_UUID";
        fsType = "btrfs";
        options = [ "subvol=home" ];
      };

    fileSystems."/nix" =
      { device = "/dev/disk/by-uuid/REPLACE_NIX_UUID";
        fsType = "btrfs";
        options = [ "subvol=nix" ];
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/REPLACE_BOOT_UUID";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

    # ── Swap ──────────────────────────────────────────────────────────────
    # TODO: substitua pelo UUID real do dispositivo de swap.
    swapDevices =
      [ { device = "/dev/disk/by-uuid/REPLACE_SWAP_UUID"; }
      ];

    # ── Plataforma ────────────────────────────────────────────────────────
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # ── Gráficos Intel UHD ────────────────────────────────────────────────
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # ── Energia (laptop) ──────────────────────────────────────────────────
    # TLP para gerenciamento avançado de energia
    services.tlp.enable = true;

    # Power management do kernel para Intel
    services.thermald.enable = true;
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

    # ── Áudio ─────────────────────────────────────────────────────────────
    # SoundWire + SOF para Intel 10th gen
    hardware.firmware = with pkgs; [
      sof-firmware
    ];
  };
}
