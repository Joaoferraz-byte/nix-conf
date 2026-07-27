{ config, ... }: {
  flake.nixosModules.nvidia = { config, ... }: {
    hardware.enableRedistributableFirmware = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      # GTX 1050 Ti (Pascal) - O suporte foi removido nos drivers mais recentes (590+).
      # Fixando no branch legacy_580 que é o último com suporte oficial para Pascal.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

      modesetting.enable = true;
      open = false; # Pascal não suporta driver open

      powerManagement.enable = false;
      powerManagement.finegrained = false;

      nvidiaSettings = true;
    };
  };
}
