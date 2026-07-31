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

        # Binds de Emergência (Removidos para evitar conflitos com o Ambxst-X)
        # O Ambxst-X é a fonte primária de configuração.
        bind = [ ];

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
        -- ── Inicialização do Ambxst-X (Lua Native) ─────────────────────────
        -- O Ambxst-X usa axctl para gerar hyprland.lua com binds e regras.
        -- Para Hyprland 0.55+, a sintaxe Lua exige concatenar com " + ".

        local ambxst_state_home = os.getenv("XDG_STATE_HOME")
          or (os.getenv("HOME") .. "/.local/state")
        local ambxst_hyprland = ambxst_state_home .. "/ambxst/hyprland.lua"

        -- Função para disparar o Ambxst shell
        local function run_ambxst()
          print("Ambxst-X: triggering shell execution")
          hl.exec_cmd("ambxst")
        end

        -- Tenta carregar a config gerada pelo axctl de forma segura.
        -- pcall garante que erros no hyprland.lua não causem Emergency Mode.
        local function load_ambxst_lua()
          local f = io.open(ambxst_hyprland, "r")
          if f then
            f:close()
            local config, err = loadfile(ambxst_hyprland)
            if config then
              local ok, run_err = pcall(config)
              if not ok then
                print("Ambxst-X: error running hyprland.lua: " .. tostring(run_err))
              end
            else
              print("Ambxst-X: syntax error in hyprland.lua: " .. tostring(err))
            end
          end
        end

        -- Binds nativos para garantir acesso básico caso o Ambxst falhe.
        -- Sintaxe Lua: MOD + KEY (com espaços e +).
        hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
        hl.bind("SUPER + R", hl.dsp.exec_cmd("ambxst --restart"))
        hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Carrega os binds dinâmicos gerados pelo axctl
        load_ambxst_lua()

        -- Garante que o shell inicie após a sessão estar pronta
        hl.on("hyprland.start", function()
          run_ambxst()
        end)
      '';
    };
  };
}
