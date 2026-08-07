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
      { device = "/dev/disk/by-label/nixos";
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
      { # Using label "boot". If the system fails to find this, ensure the partition
        # is labeled correctly (e.g., using 'fatlabel /dev/nvme0n1p1 boot') 
        # or replace this with a direct UUID for better robustness.
        device = "/dev/disk/by-label/boot";
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
