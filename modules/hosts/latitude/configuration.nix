{ self, ... }: {
  flake.nixosModules.latitudeConfiguration = { pkgs, lib, ... }: {
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

    # Boot
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.kernelPackages = pkgs.linuxPackages_zen;

    # Network
    networking.hostName = "latitude";
    networking.networkmanager.enable = true;

    # Serpantinum supports both backends; this host selects the niri session.
    desktop.profile.compositor = "niri";
    desktop.profile.shellBackend = "noctalia";

    # Bluetooth is a laptop-only capability in the shared Serpantinum setup.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };
    # Bluetooth is controlled by the Serpantinum network panel; do not start
    # Blueman's tray applet as a duplicate background application.
    services.blueman.enable = false;

    # Locale
    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "pt_BR.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_COLLATE = "pt_BR.UTF-8";
      LC_CTYPE = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MESSAGES = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };
    services.tlp = {
      enable = true;
      settings = {
        # Intel P-State supports powersave in both active and passive modes;
        # the EPP value below keeps AC operation balanced without forcing the
        # performance governor.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;
        # TLP 1.10: keep the system and the QuickShell profile deterministic.
        TLP_AUTO_SWITCH = 0;
        TLP_PROFILE_DEFAULT = "BAL";
      };
    };
    services.thermald.enable = true;

    # Keep TLP as the single power-management owner, but expose its
    # power-profiles-daemon-compatible D-Bus API to the QuickShell controls.
    services.power-profiles-daemon.enable = lib.mkForce false;
    services.tlp.pd.enable = true;

    # User
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
