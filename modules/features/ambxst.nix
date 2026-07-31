{ self, inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, ... }: {
    # Integração com o shell-conf
    imports = [ inputs.shell-conf.nixosModules.default ];

    programs.ambxst = {
      enable = true;
      package = inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # Aplicações e dependências do AMBXST
    environment.systemPackages = with pkgs; [
      # Terminal
      kitty
      tmux

      # Launcher
      fuzzel

      # Painéis de controle e ferramentas
      networkmanagerapplet
      blueman
      pavucontrol
      easyeffects
      # gradia # Removido por não estar no nixpkgs-unstable conforme auditoria

      # Ícones
      kora-icon-theme
      hicolor-icon-theme
    ];

    # Serviços necessários para harmonia do sistema (conforme auditoria)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.blueman.enable = true;
    hardware.bluetooth.enable = true;
    services.gnome.gnome-keyring.enable = true;
  };
}
