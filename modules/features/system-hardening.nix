{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, lib, ... }: {
    # segurança básica
    networking.firewall.enable = true;
    security.sudo.execWheelOnly = true; # só usuários do grupo wheel podem usar sudo
    security.protectKernelImage = true;

    # atualizações de firmware (útil pra placa-mãe, SSD, etc.)
    services.fwupd.enable = true;

    # melhor uso de disco/memória
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 20d";
    };

    zramSwap = {
      enable = true;
      memoryPercent = 50; # zram como swap comprimida na RAM, reduz uso do disco de swap
    };

    # Restringir logs do kernel apenas para root
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
    };
  };
}
