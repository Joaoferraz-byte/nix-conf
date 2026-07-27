{ self, ... }: {
  flake.nixosModules.myMachineConfiguration = { pkgs, ... }: {
    imports = [ 
      self.nixosModules.myMachineHardware
      self.nixosModules.niri
      self.nixosModules.nvidia
      self.nixosModules.greeter
      self.nixosModules.desktop-portals
      self.nixosModules.system-hardening
      self.nixosModules.flatpak
      self.nixosModules.audiorelay
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;

    # Kernel Zen para melhor performance desktop
    boot.kernelPackages = pkgs.linuxPackages_zen;
    networking.hostName = "limine";

    # Rede
    networking.networkmanager.enable = true;

    # Localização e Idioma
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

    # Teclado
    services.xserver.xkb = {
      layout = "br";
      variant = "";
    };
    console.keyMap = "br-abnt2";

    # Usuário
    users.users."livara" = {
      isNormalUser = true;
      description = "Livara";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    # Configurações Nix
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;

    # Pacotes do Sistema
    environment.systemPackages = with pkgs; [
       git
       gh
       nautilus
       brave
       vesktop
       kdePackages.okular
       foliate
       obsidian
       hydralauncher
       heroic
       jdk21
       jdk8
       jdt-language-server
       spring-boot-cli
    ];

    system.stateVersion = "24.11";
  };
}
