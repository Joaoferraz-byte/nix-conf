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
    boot.kernelPackages = pkgs.linuxPackages;

    # Network
    networking.hostName = "latitude";
    networking.networkmanager.enable = true;

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
    services.xserver.xkb = {
      layout = "br";
      variant = "abnt2";
    };
    console.keyMap = "br-abnt2";

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
    services.thermald.enable = true;

    services.power-profiles-daemon.enable = lib.mkForce false;

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
