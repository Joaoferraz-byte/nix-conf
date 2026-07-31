{ self, inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, config, lib, ... }: {
    imports = [ inputs.shell-conf.nixosModules.default ];

    programs.ambxst = {
      enable = true;
      package = inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # O shell-conf fornece um módulo de Home Manager que gerencia o estado.
    # Injetamos ele aqui para garantir que o usuário receba a configuração.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];

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
