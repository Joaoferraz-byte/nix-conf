{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, ... }: {
    networking.firewall.enable = true;
    security.sudo.execWheelOnly = true;
    security.protectKernelImage = true;
    
    services.fwupd.enable = true;

    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_userns_clone" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
    };
  };
}
