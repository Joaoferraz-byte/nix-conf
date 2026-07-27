{ self, ... }: {
  flake.nixosModules.nvidia = { config, lib, pkgs, ... }: {
    hardware.enableRedistributableFirmware = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.opengl = {
      enable = true;
      enable32Bit = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    hardware.nvidia = {
      # a partir do driver 590, a Nvidia parou de suportar Maxwell/Pascal/Volta
      # (inclui a GTX 1050 Ti) — precisa fixar no último branch que ainda suporta: 580 (LTSB)
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

      modesetting.enable = true;

      # Pascal nunca teve suporte ao driver kernel open-source (só Turing+),
      # e o branch legacy nem oferece essa opção de qualquer forma
      open = false;

      powerManagement.enable = false;
      powerManagement.finegrained = false;

      nvidiaSettings = true;
    };
  };
}
