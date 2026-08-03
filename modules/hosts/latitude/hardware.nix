# ─── Latitude Hardware ──────────────────────────────────────────
# Hardware gerado pelo nixos-generate-config.
#
# IMPORTANTE: Este arquivo é gerado automaticamente durante a instalação.
# Os UUIDs abaixo são placeholders e devem ser substituídos pelos valores
# reais da máquina após rodar `nixos-generate-config`.
#
# Para gerar os valores corretos:
#   1. Boot a partir do ISO NixOS
#   2. nixos-generate-config --root /mnt
#   3. Copie o conteúdo de /mnt/etc/nixos/hardware-configuration.nix
#      para este arquivo (substituindo os placeholders abaixo)
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
    # PLACEHOLDER: substitua os UUIDs pelos valores reais da máquina
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
    # PLACEHOLDER: substitua pelo UUID real
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
