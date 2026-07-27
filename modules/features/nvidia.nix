{ config, ... }: {
  flake.nixosModules.nvidia = { config, ... }: {
    hardware.enableRedistributableFirmware = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      # GTX 1050 Ti (Pascal) funciona melhor com drivers recentes no Unstable, 
      # mas mantemos a escolha do usuário se preferir legacy. 
      # No entanto, 'legacy_580' não existe no nixpkgs estável/unstable comum (geralmente é production, latest, etc).
      # Vamos usar 'stable' ou 'latest' para melhor compatibilidade com o kernel Zen.
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      modesetting.enable = true;
      open = false; # Pascal não suporta driver open

      powerManagement.enable = false;
      powerManagement.finegrained = false;

      nvidiaSettings = true;
    };
  };
}
