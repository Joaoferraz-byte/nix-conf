{ self, inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, config, lib, ... }: {
    # 1. Injeta o módulo NixOS do shell-conf no sistema
    imports = [ inputs.shell-conf.nixosModules.default ];

    # 2. Ativa o programa ambxst no nível do sistema
    programs.ambxst = {
      enable = true;
      package = inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # UWSM alcança graphical-session.target somente depois de importar o
    # ambiente Wayland/DBus. Associar o shell a esse alvo evita que o Lua do
    # Hyprland e um serviço systemd concorram para iniciar Quickshell.
    systemd.user.services.ambxst = {
      description = "Ambxst Quickshell session";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${config.programs.ambxst.package}/bin/ambxst";
        Restart = "on-failure";
        RestartSec = 2;
        Slice = "session.slice";
      };
    };

    # 3. Garante que o módulo de Home Manager do shell-conf seja injetado 
    # em todos os usuários que usam home-manager.
    # Isso resolve o problema de o estado mutável (~/.local/state/ambxst)
    # não ser inicializado, o que impedia o AMBXST de subir.
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
