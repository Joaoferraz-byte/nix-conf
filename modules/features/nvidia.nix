{ self, ... }: {
  flake.nixosModules.nvidia = { config, lib, pkgs, ... }: {
    hardware.enableRedistributableFirmware = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    # Sintaxe moderna para NixOS Unstable (substitui hardware.opengl)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      # Mantendo driver legacy_580 para GTX 1050 Ti
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

      modesetting.enable = true;
      open = false; # Pascal/Maxwell não suportam driver open

      powerManagement.enable = false;
      powerManagement.finegrained = false;

      nvidiaSettings = true;
    };
  };
}
