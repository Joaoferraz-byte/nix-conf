{ config, lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-partuuid/969fa740-2917-4afc-84370a720008eba63";
    fsType = "btrfs";
    options = [ "subvolid=5" "compress=zstd" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-partuuid/969fa740-2917-4afc-84370a720008eba63";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-partuuid/969fa740-2917-4afc-84370a720008eba63";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/BOOT-PARTUUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
