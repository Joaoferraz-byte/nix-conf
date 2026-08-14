{ self, ... }: {
  flake.nixosModules.myMachineConfiguration = { pkgs, lib, ... }: {
    imports = [
      self.nixosModules.myMachineHardware
      self.nixosModules.corePackages
      self.nixosModules.nvidia
      self.nixosModules.greeter
      self.nixosModules.desktop-portals
      self.nixosModules.flatpak
      self.nixosModules.audiorelay
      self.nixosModules.keyd
      self.nixosModules.system-hardening
      self.nixosModules.firejail
    ];


    # Boot
    boot.loader.systemd-boot.enable = true;
    boot.kernelParams = [ "acpi=force" "acpi=noirq" "reboot=force" "reboot=pci" "reboot=k" ];
    services.logind.settings.Login = lib.mkForce {
      HandlePowerKey = "poweroff";
      HandlePowerKeyLongPress = "poweroff";
      HandleLidSwitch = "ignore";
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.kernelPackages = pkgs.linuxPackages_zen;
    # Network
    networking.hostName = "limine";
    networking.networkmanager.enable = true;
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
    # User
    users.users."livara" = {
      isNormalUser = true;
      description = "Livara";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;
    };
    programs.zsh.enable = true;

    services."mtm1106-mode" = {
      enable = true;
      mode = "daemon";
      profile = "digimend";
      autoStart = true;
      environment.MTM1106_CONTACT_THRESHOLD = "300";
    };

    # Nix
    system.stateVersion = "26.11";
  };
}
