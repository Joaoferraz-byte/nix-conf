{ self, inputs, ... }: {
  # ── NixOS Module ────────────────────────────────────────────────────────
  flake.nixosModules.hyprland = { pkgs, lib, config, ... }:
    let
      # A entrada automática de `withUWSM` inicia o wrapper sem declarar
      # explicitamente o DesktopNames. Em versões afetadas de UWSM/Hyprland
      # isso resulta em XDG_CURRENT_DESKTOP=start-hyprland. Esta entrada é a
      # única sessão UWSM local e preserva `Hyprland` em toda a sessão.
      hyprlandUwsmSession = pkgs.writeTextFile {
        name = "hyprland-uwsm";
        text = ''
          [Desktop Entry]
          Name=Hyprland (UWSM)
          Comment=Hyprland compositor managed by UWSM
          Exec=${lib.getExe config.programs.uwsm.package} start -F -e -D Hyprland -- /run/current-system/sw/bin/start-hyprland
          Type=Application
          DesktopNames=Hyprland
          Keywords=hyprland;wayland;compositor;
        '';
        destination = "/share/wayland-sessions/hyprland-uwsm.desktop";
        derivationArgs.passthru.providedSessions = [ "hyprland-uwsm" ];
      };
    in {
      programs.hyprland = {
        enable = true;
        # A entrada automática gerada por esta opção não permite passar
        # `-e -D Hyprland` ao UWSM. A sessão declarada acima a substitui.
        withUWSM = false;
        xwayland.enable = true;
      };
      # Mantém as unidades UWSM, a importação de ambiente e a integração
      # systemd da sessão, sem criar uma segunda entrada hyprland-uwsm.
      programs.uwsm.enable = true;
      environment.systemPackages = with pkgs; [
        hyprlandUwsmSession
        grim
        slurp
        wl-clipboard
        brightnessctl
        bibata-cursors
        wev
        playerctl
      ];
      # A entrada aparece no display manager como "Hyprland (UWSM)". Ela usa
      # start-hyprland e força XDG_CURRENT_DESKTOP=Hyprland antes do compositor.
      services.displayManager.sessionPackages = [ hyprlandUwsmSession ];
      home-manager.sharedModules = [
        # UWSM é a única autoridade da sessão systemd; o módulo Home Manager
        # não pode criar uma sessão Hyprland concorrente.
        { wayland.windowManager.hyprland.systemd.enable = false; }
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
      # settings vazio: toda a config vai em extraConfig via Lua puro.
      settings = {};
      extraConfig = ''
        -- Monitor padrão
        hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

        -- Input
        hl.config({
          input = {
            kb_layout = "br",
            follow_mouse = 1,
            sensitivity = 0,
            touchpad = {
              natural_scroll = true,
              tap_to_click   = true,
            },
          },
          general = {
            layout = "dwindle",
            gaps_in = 5,
            gaps_out = 10,
            border_size = 2,
          },
          decoration = {
            rounding = 16,
            drop_shadow = true,
            shadow_range = 4,
            shadow_render_power = 3,
            blur = {
              enabled = true,
              size = 8,
              passes = 2,
            },
          },
          misc = {
            force_default_wallpaper = 0,
            disable_hyprland_logo   = true,
          },
        })

        hl.config({ dwindle = { preserve_split = true } })

        -- Binds de recuperação e nativos (garantem funcionalidade básica se o shell falhar).
        local mainMod = "SUPER"
        
        -- Terminal e Shell
        hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
        hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("ambxst run tmux"))
        hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("systemctl --user restart ambxst.service"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Atalhos Core Ambxst (IPC)
        hl.bind(mainMod,                hl.dsp.exec_cmd("ambxst run launcher"))
        hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("ambxst run dashboard"))
        hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd("ambxst run assistant"))
        hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("ambxst run clipboard"))
        hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("ambxst run emoji"))
        hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("ambxst run notes"))
        hl.bind(mainMod .. " + COMMA",  hl.dsp.exec_cmd("ambxst run wallpapers"))
        hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("ambxst run config"))
        hl.bind(mainMod .. " + TAB",    hl.dsp.exec_cmd("ambxst run overview"))
        hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("ambxst run powermenu"))
        hl.bind(mainMod .. " + S",      hl.dsp.exec_cmd("ambxst run tools"))
        hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("ambxst run screenshot"))
        hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("ambxst run screenrecord"))
        hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("ambxst run lens"))
        hl.bind(mainMod .. " + ALT + B",   hl.dsp.exec_cmd("ambxst reload"))
        hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("ambxst quit"))
        hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("loginctl lock-session"))

        -- Atalhos de Sistema Hyprland
        hl.bind(mainMod .. " + C",      hl.dsp.killactive())
        hl.bind(mainMod .. " + F",      hl.dsp.togglefloating())
        hl.bind(mainMod .. " + P",      hl.dsp.pseudo())
        hl.bind(mainMod .. " + J",      hl.dsp.togglesplit())
        hl.bind(mainMod .. " + M",      hl.dsp.fullscreen())

        -- Navegação de Janelas
        hl.bind(mainMod .. " + Left",   hl.dsp.movefocus("l"))
        hl.bind(mainMod .. " + Right",  hl.dsp.movefocus("r"))
        hl.bind(mainMod .. " + Up",     hl.dsp.movefocus("u"))
        hl.bind(mainMod .. " + Down",   hl.dsp.movefocus("d"))
        
        hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.movewindow("l"))
        hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.movewindow("r"))
        hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.movewindow("u"))
        hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.movewindow("d"))

        -- Workspaces (1-10)
        for i = 1, 9 do
          hl.bind(mainMod .. " + " .. i, hl.dsp.workspace(tostring(i)))
          hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.movetoworkspace(tostring(i)))
        end
        hl.bind(mainMod .. " + 0", hl.dsp.workspace("10"))
        hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.movetoworkspace("10"))

        -- Mouse Binds
        hl.bindm(mainMod, "mouse:272", hl.dsp.movewindow())
        hl.bindm(mainMod, "mouse:273", hl.dsp.resizewindow())

        -- Atalhos de Hardware (Media/Volume/Brightness)
        hl.bind("l",  "XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"))
        hl.bind("l",  "XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"))
        hl.bind("l",  "XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"))
        hl.bind("le", "XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
        hl.bind("le", "XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"))
        hl.bind("le", "XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        hl.bind("le", "XF86MonBrightnessUp",   hl.dsp.exec_cmd("ambxst brightness +5"))
        hl.bind("le", "XF86MonBrightnessDown", hl.dsp.exec_cmd("ambxst brightness -5"))

        -- Ambxst é iniciado pela unidade systemd `ambxst.service`, associada
        -- a graphical-session.target. Não iniciar pelo Lua evita duplicidade
        -- e garante que o ambiente UWSM já tenha sido importado.
      '';
    };
  };
}
