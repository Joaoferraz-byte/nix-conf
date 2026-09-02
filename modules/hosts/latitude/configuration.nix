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
    networking.networkmanager = {
      enable = true;
      # The diagnostic showed iwlwifi missed beacons and repeated handshake
      # timeouts. Disable NM Wi-Fi power saving to test the unstable-link
      # hypothesis; this does not toggle the global radio state.
      wifi.powersave = false;
    };

    # niri is the sole compositor and Noctalia is the visual shell.
    desktop.profile.compositor = "niri";

    # Bluetooth is a laptop-only capability in the shared desktop setup.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };
    # Bluetooth is exposed through the desktop session/BlueZ integration; do not start
    # Blueman's tray applet as a duplicate background application.
    services.blueman.enable = false;

    # Locale
    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_COLLATE = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
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
        # TLP 1.10: keep the system profile deterministic.
        TLP_AUTO_SWITCH = 0;
        # Keep TLP from re-enabling adapter power saving on either power
        # source. This targets link instability, not rfkill/radio state.
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "off";
        TLP_PROFILE_DEFAULT = "BAL";
      };
    };
    services.thermald.enable = true;

    # Noctalia's battery widget reads the laptop battery through UPower.
    # This is intentionally laptop-only; myMachine is a desktop.
    services.upower.enable = true;

    # Keep TLP as the single power-management owner on this laptop.
    services.power-profiles-daemon.enable = lib.mkForce false;
    services.tlp.pd.enable = true;

    # GameMode is an on-demand client/daemon integration exposed by the
    # Noctalia session. On the Latitude, TLP remains the sole
    # power-management owner; GameMode switches the CPU governor to
    # `performance` directly via sysfs/cpupower (desiredgov) when a game
    # requests it, and TLP restores `powersave` once the request is
    # released. This does NOT enable power-profiles-daemon (kept disabled
    # above) and does not conflict with TLP's profile policy.
    programs.gamemode = {
      enable = true;
      enableRenice = false;
      settings.general = {
        desiredgov = "performance";
        inhibit_screensaver = 1;
      };
    };

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
