{ self, ... }: {
  flake.nixosModules.latitudeConfiguration = { pkgs, ... }: {
    imports = [
      self.nixosModules.latitudeHardware
      self.nixosModules.corePackages
      self.nixosModules.greeter
      self.nixosModules.desktop-portals
      self.nixosModules.flatpak
      self.nixosModules.audiorelay
      self.nixosModules.keyd
      self.nixosModules.system-hardening
    ];

    # ── Boot ──────────────────────────────────────────────────────────────
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest; # Better support for 10th gen Intel

    # ── Rede ──────────────────────────────────────────────────────────────
    networking.hostName = "latitude";
    networking.networkmanager.enable = true;

    # ── Local ─────────────────────────────────────────────────────────────
    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    
    # Keyboard: Irish (IE)
    services.xserver.xkb = {
      layout = "ie";
      variant = "";
    };
    console.keyMap = "ie";

    # ── Power Management ──────────────────────────────────────────────────
    # Latitude 5410 is a laptop, so we need proper power management.
    # DankMaterialShell monitors system state, but NixOS needs the backend.
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;
      };
    };
    services.thermald.enable = true; # Prevents overheating on Dell laptops

    # ── Usuário ───────────────────────────────────────────────────────────
    users.users."livara" = {
      isNormalUser = true;
      description = "Livara";
      extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
      shell = pkgs.zsh;
    };
    programs.zsh.enable = true;

    system.stateVersion = "26.11";
  };
}
