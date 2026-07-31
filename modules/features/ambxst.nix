{ self, inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, config, lib, ... }: {
    # Importa o módulo NixOS do shell-conf que define as opções do AMBXST
    imports = [ inputs.shell-conf.nixosModules.default ];

    # Configuração do pacote e ativação do serviço no nível do sistema
    programs.ambxst = {
      enable = true;
      package = inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # O shell-conf fornece um módulo de Home Manager que gerencia o estado.
    # Como você usa sharedModules no hyprland.nix, o módulo do shell-conf
    # deve ser incluído lá ou aqui via sharedModules.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];

    # Aplicações e dependências do AMBXST
    environment.systemPackages = with pkgs; [
      kitty
      tmux
      fuzzel
      networkmanagerapplet
      blueman
      pavucontrol
      easyeffects
      kora-icon-theme
      hicolor-icon-theme
    ];

    # Serviços necessários para harmonia do sistema
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.blueman.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.gnome.gnome-keyring.enable = lib.mkDefault true;
  };
}
