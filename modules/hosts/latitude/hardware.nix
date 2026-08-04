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
      { device = "/dev/disk/by-label/nixos"; # Assumes label-based mounting for portability
        fsType = "btrfs";
        options = [ "subvol=root" "compress=zstd" ];
      };

    fileSystems."/home" =
      { device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = [ "subvol=home" "compress=zstd" ];
      };

    fileSystems."/nix" =
      { device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = [ "subvol=nix" "compress=zstd" "noatime" ];
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-label/boot";
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
