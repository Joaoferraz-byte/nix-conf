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

        # Autostart do Ambxst via exec-once padrão do Hyprland.
        # Isso garante que o shell suba após o ambiente estar pronto.
        exec_once = [ "ambxst" ];
      };

      extraConfig = ''
        -- ── Integração Nativa do Ambxst-X ─────────────────────────────────
        -- O Ambxst-X gera hyprland.lua dinamicamente. Esta linha carrega
        -- os binds e regras gerados sem a necessidade de bootstrap complexo.
        -- O pcall garante que erros no arquivo gerado não causem crash.

        local ambxst_state_home = os.getenv("XDG_STATE_HOME")
          or (os.getenv("HOME") .. "/.local/state")
        local ambxst_hyprland = ambxst_state_home .. "/ambxst/hyprland.lua"

        local function load_ambxst_lua()
          local f = io.open(ambxst_hyprland, "r")
          if f then
            f:close()
            local config, err = loadfile(ambxst_hyprland)
            if config then
              pcall(config)
            end
          end
        end

        -- Binds de recuperação nativos (Sintaxe Lua MOD + KEY)
        hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
        hl.bind("SUPER + R", hl.dsp.exec_cmd("ambxst --restart"))
        hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Carrega a configuração dinâmica do Ambxst
        load_ambxst_lua()
      '';
    };
  };
}
