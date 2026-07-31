# ─── Hyprland Wayland Compositor ───────────────────────────────────────────
# O Home Manager 26.05+ gera hyprland.lua por padrão. Esta configuração usa a
# API Lua do Hyprland 0.55+ e evita misturar sintaxe Hyprlang no arquivo Lua.
#
# BUG FIX (nixpkgs#476375): ao iniciar o Hyprland via UWSM no NixOS, o
# XDG_CURRENT_DESKTOP fica setado como "start-hyprland" em vez de "Hyprland"
# porque o binPath do waylandCompositors aponta para o wrapper "start-hyprland".
# Correção em duas camadas:
#   1. binPath aponta para o binário real do Hyprland (não o wrapper UWSM).
#   2. environment.sessionVariables normaliza XDG_CURRENT_DESKTOP=Hyprland
#      para garantir que qualquer ferramenta que leia essa variável (incluindo
#      o Ambxst/axctl) receba o valor correto.
{ self, inputs, ... }: {
  # ── NixOS Module ────────────────────────────────────────────────────────
  flake.nixosModules.hyprland = { pkgs, lib, ... }: {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    # Registra a sessão Hyprland no UWSM com o binário real do compositor.
    # Usar "start-hyprland" como binPath é a causa raiz do bug #476375:
    # o UWSM propaga o nome do wrapper como XDG_CURRENT_DESKTOP.
    programs.uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment     = "Hyprland compositor managed by UWSM";
      # Aponta para o binário real — não para o wrapper start-hyprland —
      # para que o UWSM registre XDG_CURRENT_DESKTOP=Hyprland corretamente.
      binPath = "${pkgs.hyprland}/bin/Hyprland";
    };

    # Normalização explícita de XDG_CURRENT_DESKTOP como segunda camada de
    # defesa. Isso garante que mesmo em sessões iniciadas por display managers
    # que não passem pelo UWSM o valor seja consistente.
    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = lib.mkDefault "Hyprland";
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
  flake.homeManagerModules.hyprland = { pkgs, lib, ... }: {
    home.pointerCursor = {
      enable  = true;
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    wayland.windowManager.hyprland = {
      enable     = true;
      configType = "lua";
      systemd.enable = false;

      settings = {
        mod._var = "SUPER";

        monitor = {
          output   = "";
          mode     = "preferred";
          position = "auto";
          scale    = 1;
        };

        config = {
          input = {
            kb_layout = "br";
            touchpad = {
              natural_scroll = true;
              tap_to_click   = true;
            };
          };
          general.layout = "dwindle";
        };

        # Binds de Emergência (Nível Nix)
        # Estes binds garantem que o sistema seja utilizável mesmo se o Ambxst
        # falhar. O Ambxst pode adicionar outros binds via axctl, mas estes
        # permanecem como fallback de recuperação.
        bind = [
          "SUPER_SHIFT, Q, exec, uwsm stop"    # Sair da sessão UWSM
          "SUPER, Return, exec, kitty"          # Terminal de emergência
          "SUPER, R, exec, ambxst --restart"    # Reiniciar o shell manualmente
        ];

        window_rule = [
          {
            match.class = "^(quickshell)$";
            no_blur   = true;
            no_shadow = true;
            decorate  = false;
            rounding  = 0;
          }
        ];
      };

      extraConfig = ''
        -- ── Inicialização Resiliente do Ambxst-X ──────────────────────────
        -- O Ambxst-X usa axctl para gerar hyprland.lua com binds e regras.
        -- Na primeira sessão esse arquivo ainda não existe; nas seguintes ele
        -- já foi gerado pelo axctl na sessão anterior.
        --
        -- Estratégia:
        --   1. Tenta carregar o hyprland.lua gerado pelo axctl (sessões normais).
        --   2. Se não existir ou falhar, inicia o Ambxst diretamente para que
        --      ele gere o arquivo (primeiro boot ou após reset).
        --   3. O evento "hyprland.start" garante que o Ambxst suba em toda
        --      nova sessão, independentemente do caminho acima.
        --
        -- NOTA: exec-once não é usado aqui porque o Ambxst precisa de um
        -- ambiente de sessão completo (D-Bus, pipewire, portals) que o UWSM
        -- garante antes de disparar "hyprland.start".

        local ambxst_state_home = os.getenv("XDG_STATE_HOME")
          or (os.getenv("HOME") .. "/.local/state")
        local ambxst_hyprland = ambxst_state_home .. "/ambxst/hyprland.lua"

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

        -- Garante que o shell inicie em novos logins/eventos de sessão
        hl.on("hyprland.start", function()
          run_ambxst()
        end)
      '';
    };
  };
}
