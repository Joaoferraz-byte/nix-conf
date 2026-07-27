{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, ... }: {
    # Segurança básica
    networking.firewall.enable = true;
    security.sudo.execWheelOnly = true;
    security.protectKernelImage = true;
    
    # Prevenção de ataques via USB/DMA (opcional, mas recomendado para laptops)
    # boot.blacklistedKernelModules = [ "firewire-ohci" "thunderbolt" ];

    # Atualizações de firmware
    services.fwupd.enable = true;

    # Otimização Nix
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # Memória
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    # Restrições de Kernel
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_userns_clone" = 1; # Necessário para sandboxing de navegadores
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
    };
    
    # Habilitar microcode update
    hardware.cpu.amd.updateMicrocode = true; # Assume AMD baseado no Zen kernel e hardware.nix anterior
  };
}
