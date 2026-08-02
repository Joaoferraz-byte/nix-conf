{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, config, ... }: {
    programs.niri.enable = true;

    # Habilita o suporte a UWSM para o Niri, se disponível
    # programs.uwsm.enable = true; 

    environment.systemPackages = with pkgs; [
      xwayland-satellite # Para rodar apps X11 no Niri
      swaybg
      waybar
      fuzzel
      kitty
    ];
  };

  flake.homeManagerModules.niri = { pkgs, lib, config, ... }: {
    programs.niri = {
      enable = true;
      # Configuração mínima para evitar erros de inicialização
      settings = {
        input.keyboard.xkb.layout = "br";
        layout.gaps = 8;
        # O DMS vai gerenciar a maioria das binds se habilitado no shell-conf
      };
    };
  };
}
