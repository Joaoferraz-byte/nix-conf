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
  flake.homeManagerModules.hyprland = { lib, ... }:
    let
      lua = lib.generators.mkLuaInline;

      # Cria `hl.bind(<teclas>, <dispatcher>, <flags?>)` preservando expressões
      # Lua para a variável `mod` e serializando as flags como tabela Lua.
      mkBind = keyExpression: dispatcher: flags: {
        _args = [ (lua keyExpression) (lua dispatcher) ]
          ++ lib.optional (flags != { }) flags;
      };
      modBind = suffix: dispatcher: flags:
        mkBind ''mod .. " + ${suffix}"'' dispatcher flags;
      keyBind = key: dispatcher: flags:
        mkBind (builtins.toJSON key) dispatcher flags;
    in {
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

          # Regras permanentes para superfícies do Quickshell. As regras de
          # camada e aparência dinâmicas continuam sob responsabilidade do
          # arquivo Lua gerado pelo axctl.
          window_rule = [
            {
              match.class = "^(quickshell)$";
              no_blur = true;
              no_shadow = true;
              decorate = false;
              rounding = 0;
            }
          ];

          bind = [
            # Aplicações
            (modBind "RETURN" ''hl.dsp.exec_cmd("alacritty")'' { })
            (modBind "O" ''hl.dsp.exec_cmd("obsidian")'' { })
            (modBind "W" ''hl.dsp.exec_cmd("brave")'' { })
            (modBind "E" ''hl.dsp.exec_cmd("nautilus")'' { })

            # Janelas
            (modBind "Q" "hl.dsp.window.close()" { })
            (modBind "F" ''hl.dsp.window.fullscreen({ action = "set" })'' { })
            (modBind "SHIFT + F" ''hl.dsp.window.fullscreen({ action = "unset" })'' { })
            (modBind "SHIFT + V" ''hl.dsp.window.float({ action = "toggle" })'' { })

            # Foco e movimentação
            (modBind "LEFT" ''hl.dsp.focus({ direction = "l" })'' { })
            (modBind "RIGHT" ''hl.dsp.focus({ direction = "r" })'' { })
            (modBind "UP" ''hl.dsp.focus({ direction = "u" })'' { })
            (modBind "DOWN" ''hl.dsp.focus({ direction = "d" })'' { })
            (modBind "SHIFT + LEFT" ''hl.dsp.window.move({ direction = "l" })'' { })
            (modBind "SHIFT + RIGHT" ''hl.dsp.window.move({ direction = "r" })'' { })
            (modBind "SHIFT + UP" ''hl.dsp.window.move({ direction = "u" })'' { })
            (modBind "SHIFT + DOWN" ''hl.dsp.window.move({ direction = "d" })'' { })

            # Workspaces
            (modBind "1" ''hl.dsp.focus({ workspace = "1" })'' { })
            (modBind "2" ''hl.dsp.focus({ workspace = "2" })'' { })
            (modBind "3" ''hl.dsp.focus({ workspace = "3" })'' { })
            (modBind "4" ''hl.dsp.focus({ workspace = "4" })'' { })
            (modBind "SHIFT + 1" ''hl.dsp.window.move({ workspace = "1" })'' { })
            (modBind "SHIFT + 2" ''hl.dsp.window.move({ workspace = "2" })'' { })
            (modBind "SHIFT + 3" ''hl.dsp.window.move({ workspace = "3" })'' { })
            (modBind "SHIFT + 4" ''hl.dsp.window.move({ workspace = "4" })'' { })
            # `Next` e `Prior` são os keysyms canônicos de Page Down/Up.
            (modBind "Next" ''hl.dsp.focus({ workspace = "e+1" })'' { })
            (modBind "Prior" ''hl.dsp.focus({ workspace = "e-1" })'' { })

            # Captura de tela
            (keyBind "PRINT" ''hl.dsp.exec_cmd("grim -g '$(slurp)' - | wl-copy")'' { })
            (modBind "PRINT" ''hl.dsp.exec_cmd("grim - | wl-copy")'' { })

            # Áudio e brilho: flags Lua substituem bindel/bindl da sintaxe antiga.
            (keyBind "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")'' { repeating = true; })
            (keyBind "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'' { repeating = true; })
            (keyBind "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("brightnessctl set +5%")'' { repeating = true; })
            (keyBind "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightnessctl set 5%-")'' { repeating = true; })
            (keyBind "XF86AudioMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'' { locked = true; })

            # Encerramento explícito da sessão.
            (modBind "SHIFT + E" "hl.dsp.exit()" { })
          ];
        };

        extraConfig = ''
          -- Ambxst-X/axctl gera este arquivo dinamicamente a partir dos JSONs.
          -- A configuração principal permanece inicializável mesmo no primeiro
          -- login, antes de o arquivo existir, e nunca executa `loadfile(nil)`.
          local ambxst_data_home = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
          local ambxst_hyprland = ambxst_data_home .. "/ambxst/hyprland.lua"
          local ambxst_config, ambxst_error = loadfile(ambxst_hyprland)

          if ambxst_config then
            local loaded, load_error = pcall(ambxst_config)
            if not loaded then
              print("Ambxst-X: failed to load generated Hyprland Lua: " .. tostring(load_error))
            end
          else
            print("Ambxst-X: generated Hyprland Lua not present yet: " .. tostring(ambxst_error))
            hl.on("hyprland.start", function()
              hl.exec_cmd("ambxst")
            end)
          end
        '';
      };
    };
}
