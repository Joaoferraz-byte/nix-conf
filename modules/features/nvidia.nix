{ config, ... }: {
  flake.nixosModules.nvidia = { config, ... }: {
    hardware.enableRedistributableFirmware = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

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
