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
    # P3 fix — shutdown does not power the machine off (blue light stays on,
    # requires holding the power button):
    # 1. "acpi=force" forces ACPI off even when the DSDT is incomplete.
    # 2. "reboot=pci" routes the ACPI reset/poweroff path through the PCI
    #    bus, which is the variant most often needed on AMD desktop boards
    #    whose BIOS ignores the normal S5 poweroff sequence.
    # Note: the two "Power Button" devices in libinput (event15/event16)
    # are normal — one physical PNP0C0C button and one virtual ACPI button
    # — they are not the cause; the root cause is ACPI S5 routing.
    boot.kernelParams = [ "acpi=force" "acpi=noirq" "reboot=force" "reboot=pci" "reboot=k" ];
    # Bind the power key to a clean systemd poweroff so that presses from
    # either input device (physical PNP0C0C / virtual ACPI button) reach
    # systemd-poweroff.service.
    # NOTE: the legacy `services.logind.handlePowerKey` and `lidSwitch`
    # options were removed in nixos-unstable (2026). The logind module now
    # exposes a single freeform submodule `services.logind.settings.Login`
    # that maps directly to logind.conf(5).
    # mkForce: systemd's logind default is `HandlePowerKey = "poweroff"`,
    # but a module imported later (e.g. the desktop-portals stack) could
    # override it with `lib.mkOverride` of lower priority than mkForce.
    # Forcing it guarantees a single press on either power input device
    # reaches systemd-poweroff.service instead of requiring the button
    # to be held.
    services.logind.settings.Login = lib.mkForce {
      HandlePowerKey = "poweroff";
      HandlePowerKeyLongPress = "poweroff";
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

    # MTM-1106/T501: the kernel hid-generic driver caches the 8-byte
    # mobile-area report descriptor and cannot be made to reload the
    # 64-byte full-area one reliably, so the tablet is now driven from
    # userspace: mtm1106-daemon switches the firmware to full-area mode
    # and injects pen/hotkey events via uinput for the whole device
    # lifetime, reconnecting automatically. If input breaks, set
    # mode = "oneshot" and rebuild as a fallback.
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
