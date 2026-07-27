{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, lib, ... }: {
    networking.firewall.enable = true;
    security.sudo.execWheelOnly = true;
    security.protectKernelImage = true;
    services.fwupd.enable = true;
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 20d";
    };
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };
  };
}
