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

    # UWSM deve iniciar o wrapper oficial, não o binário Hyprland diretamente.
    # Isso mantém as variáveis XDG e os targets de sessão consistentes.
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

    # A sessão é gerenciada por UWSM; o Home Manager continua responsável
    # somente por escrever hyprland.lua.
    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.systemd.enable = false;
      }
    ];
  };

  # ── Home Manager Module ─────────────────────────────────────────────────
  flake.homeManagerModules.hyprland = { pkgs, ... }: {
    # Configuração do cursor (Bibata)
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
        # Variável Lua local: local mod = "SUPER"
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

          # Gaps, blur, bordas e animações são aplicados pelo Ambxst-X/axctl.
          general.layout = "dwindle";
        };

        # Regras permanentes para superfícies do Quickshell.
        window_rule = [
          {
            match.class = "^(quickshell)$";
            no_blur = true;
            no_shadow = true;
            decorate = false;
            rounding = 0;
          }
        ];

        # AMBXST/axctl é a fonte única de atalhos interativos.
        bind = [ ];
      };

      extraConfig = ''
        -- Ambxst-X/axctl gera este arquivo dinamicamente a partir dos JSONs.
        local ambxst_data_home = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
        local ambxst_hyprland = ambxst_data_home .. "/ambxst/hyprland.lua"
        local ambxst_config, ambxst_error = loadfile(ambxst_hyprland)

        local function start_ambxst_fallback(reason)
          print("Ambxst-X: " .. reason .. "; starting the shell fallback")
          hl.on("hyprland.start", function()
            hl.exec_cmd("ambxst")
          end)
        end

        if ambxst_config then
          local loaded, load_error = pcall(ambxst_config)
          if not loaded then
            start_ambxst_fallback("failed to load generated Hyprland Lua: " .. tostring(load_error))
          end
        else
          start_ambxst_fallback("generated Hyprland Lua not present yet: " .. tostring(ambxst_error))
        end
      '';
    };
  };
}
