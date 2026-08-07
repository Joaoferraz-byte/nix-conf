{ ... }: {
  flake.nixosModules.latitudeHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    fileSystems."/" =
      { device = "/dev/disk/by-partuuid/ROOT-PARTUUID";
        fsType = "btrfs";
        options = [ "subvol=root" "compress=zstd" ];
      };

    fileSystems."/home" =
      { device = "/dev/disk/by-partuuid/ROOT-PARTUUID";
        fsType = "btrfs";
        options = [ "subvol=home" "compress=zstd" ];
      };

    fileSystems."/nix" =
      { device = "/dev/disk/by-partuuid/ROOT-PARTUUID";
        fsType = "btrfs";
        options = [ "subvol=nix" "compress=zstd" "noatime" ];
      };

    # NOTE: ROOT-PARTUUID must be replaced with the real partition UUID of
    # the Btrfs device (same one the former "nixos" label referred to).
    # Get it on the laptop with `lsblk -o NAME,PARTUUID`. Keeping the four
    # root subvolumes on a single physical partition guarantees that the
    # "Failed to unmount /home" error during emergency switch-root
    # disappears — only one device to tear down.

    # P2 fix: the previous by-label "boot" reference caused
    # "Timed out waiting for device /dev/disk/by-label/boot" and put the
    # system into emergency mode whenever the EFI partition lost its label
    # (repartitioning, reformatting, reinstallation). A partition UUID
    # never changes, so it is the robust choice. Before rebuilding on the
    # actual laptop, replace the placeholder with the real value from
    # `lsblk -o NAME,PARTUUID /dev/nvme0n1p1` or, alternatively, restore
    # the label with `sudo fatlabel /dev/nvme0n1p1 boot` and switch back
    # to by-label. The same applies to the "nixos" Btrfs label below.
    fileSystems."/boot" =
      { device = "/dev/disk/by-partuuid/BOOT-PARTUUID";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

    swapDevices = [ ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # Enable graphics for Intel integrated GPU
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
