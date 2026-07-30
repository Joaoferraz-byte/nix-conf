{ self, ... }: {
  flake.nixosModules.nvidia = { config, lib, pkgs, ... }: {
    hardware.enableRedistributableFirmware = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    boot.kernelModules = [
      "nvidia"
      "nvidia_modeset"
    ];
    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      modesetting.enable = true;
      open = false;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
    };
  };
}
