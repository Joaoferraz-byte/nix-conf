{ self, ... }: {
  flake.nixosModules.myMachineConfiguration = { pkgs, ... }: {
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
    ];
    

    # Boot
    boot.loader.systemd-boot.enable = true;
    # P3 fix — shutdown does not power the machine off (blue light stays on,
    # requires holding the power button):
    # 1. "acpi=force" forces ACPI off even when the DSDT is incomplete.
    # 2. "reboot=pci" routes the ACPI reset/poweroff path through the PCI
    #    bus, which is the variant most often needed on AMD desktop boards
    #    whose BIOS ignores the normal S5 poweroff sequence.
    # Note: the two "Power Button" devices in libinput (event15/event16)
    # are normal — one physical PNP0C0C button and one virtual ACPI button
    # — they are not the cause; the root cause is ACPI S5 routing.
    boot.kernelParams = [ "acpi=force" "reboot=pci" ];
    # Bind the power key to a clean systemd poweroff so that presses from
    # either input device (physical PNP0C0C / virtual ACPI button) reach
    # systemd-poweroff.service.
    # NOTE: the legacy `services.logind.handlePowerKey` and `lidSwitch`
    # options were removed in nixos-unstable (2026). The logind module now
    # exposes a single freeform submodule `services.logind.settings.Login`
    # that maps directly to logind.conf(5).
    services.logind.settings.Login = {
      HandlePowerKey = "poweroff";
      HandleLidSwitch = "ignore";
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.kernelPackages = pkgs.linuxPackages_zen;
    # Rede
    networking.hostName = "limine";
    networking.networkmanager.enable = true;
    # Local
    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };
    services.xserver.xkb = {
      layout = "br";
      variant = "";
    };
    console.keyMap = "br-abnt2";
    # Usuário
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

    # P1 — MTM-1106/T501: install the reverse-engineered USB mode
    # activator. autoStart stays OFF until the physical tablet has been
    # validated on this machine (per mesa-tomate-driver/TESTING.md:
    # "Do not treat a cursor change as proof of success").
    # Enable with: `sudo systemctl start mtm1106-mode.service`
    services."mtm1106-mode" = {
      enable = true;
      profile = "digimend";
      autoStart = false;
    };

    # Nix
    system.stateVersion = "26.11";
  };
}
