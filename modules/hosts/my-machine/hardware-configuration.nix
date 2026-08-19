# Generated from the mounted target topology by generate-hardware.sh.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "sd_mod"
    "btrfs"
    "vfat"
    "usbhid"
    "usb_storage"
    "xhci_pci"
  ];
  boot.initrd.kernelModules = [ "btrfs" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/7dc93333-9e9a-4ed8-adc6-a9e021464687";
    fsType = "btrfs";
    options = [ "subvolid=5" "subvol=/" ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/7dc93333-9e9a-4ed8-adc6-a9e021464687";
    fsType = "btrfs";
    options = [ "subvolid=257" "subvol=/nix" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/7dc93333-9e9a-4ed8-adc6-a9e021464687";
    fsType = "btrfs";
    options = [ "subvolid=256" "subvol=/home" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E21D-EFCE";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/79febc52-42dd-4d8e-ba13-eea976778dfb"; }
    { device = "/dev/disk/by-uuid/73f0052c-6927-45c4-b3a2-8cdc4cbd0d8b"; }
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
