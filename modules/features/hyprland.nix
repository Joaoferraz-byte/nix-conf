# ─── Hyprland Wayland Compositor ───────────────────────────────────────────
# O Home Manager 26.05+ gera hyprland.lua por padrão. Esta configuração usa a
# API Lua do Hyprland 0.55+ e evita misturar sintaxe Hyprlang no arquivo Lua.
{ self, inputs, ... }: {
  # ── NixOS Module ────────────────────────────────────────────────────────
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    programs.uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/start-hyprland";
    };

    environment.systemPackages = with pkgs; [
      grim
      slurp
      wl-clipboard
      brightnessctl
      bibata-cursors
      wev
    ];

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.systemd.enable = false;
      }
    ];
  };

  # ── Home Manager Module ─────────────────────────────────────────────────
  flake.homeManagerModules.hyprland = { pkgs, ... }: {
    home.pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      systemd.enable = false;

      settings = {
        mod._var = "SUPER";

        monitor = {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1;
        };

        config = {
          input = {
            kb_layout = "br";
            touchpad = {
              natural_scroll = true;
              tap_to_click = true;
            };
          };
          general.layout = "dwindle";
        };

        # Binds de Emergência (Nível Nix)
        # Estes binds garantem que o sistema seja utilizável mesmo se o AMBXST falhar.
        # O AMBXST pode adicionar outros binds, mas estes permanecem como fallback.
        bind = [
          "SUPER_SHIFT, Q, exec, uwsm stop"        # Sair da sessão
          "SUPER, Return, exec, kitty"             # Abrir terminal de emergência
          "SUPER, R, exec, ambxst --restart"       # Reiniciar o shell manualmente
        ];

        window_rule = [
          {
            match.class = "^(quickshell)$";
            no_blur = true;
            no_shadow = true;
            decorate = false;
            rounding = 0;
          }
        ];
      };

      extraConfig = ''
        -- Lógica de Inicialização Resiliente do Ambxst-X
        local ambxst_data_home = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
        local ambxst_hyprland = ambxst_data_home .. "/ambxst/hyprland.lua"
        
        local function run_ambxst()
          print("Ambxst-X: triggering shell execution")
          hl.exec_cmd("ambxst")
        end

        -- Tenta carregar a config gerada pelo axctl
        local ambxst_config, ambxst_error = loadfile(ambxst_hyprland)

        if ambxst_config then
          local loaded, load_error = pcall(ambxst_config)
          if not loaded then
            print("Ambxst-X: failed to load generated Lua: " .. tostring(load_error))
            run_ambxst()
          end
        else
          print("Ambxst-X: generated Lua not found: " .. tostring(ambxst_error))
          -- Se não houver config, inicia o shell imediatamente para que ele a gere
          run_ambxst()
        end

        -- Garante que o shell inicie em novos logins/eventos
        hl.on("hyprland.start", function()
          run_ambxst()
        end)
      '';
    };
  };
}
