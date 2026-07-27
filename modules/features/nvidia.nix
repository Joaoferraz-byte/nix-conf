{ config, ... }: {
  flake.nixosModules.nvidia = { config, ... }: {
    hardware.enableRedistributableFirmware = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      # GTX 1050 Ti (Pascal) funciona melhor com drivers recentes no Unstable.
      # Usamos 'stable' para melhor compatibilidade com o kernel Zen.
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      modesetting.enable = true;
      open = false; # Pascal não suporta driver open

      powerManagement.enable = false;
      powerManagement.finegrained = false;

      nvidiaSettings = true;
    };
  };
}
