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
        -- Estes atalhos são idênticos aos definidos no adapter default do shell-conf
        -- e são a única fonte de binds Hyprland — o CompositorKeybinds foi removido
        -- do shell.qml para evitar conflitos com esta camada declarativa.
        local mainMod = "SUPER"

        -- Terminal e Shell
        hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
        hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("ambxst run tmux"))
        hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("systemctl --user restart ambxst.service"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Atalhos Core Ambxst (IPC)
        -- Launcher: apenas Super (sem modificador adicional).
        hl.bind(mainMod,                hl.dsp.exec_cmd("ambxst run launcher"))
        -- Dashboard, Assistant, Clipboard, Emoji, Notes, Wallpapers
        hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("ambxst run dashboard"))
        hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd("ambxst run assistant"))
        hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("ambxst run clipboard"))
        hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("ambxst run emoji"))
        hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("ambxst run notes"))
        hl.bind(mainMod .. " + COMMA",  hl.dsp.exec_cmd("ambxst run wallpapers"))
        -- System utilities
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
        -- Close, Float, Pseudo, Split, Fullscreen
        hl.bind(mainMod .. " + C",      hl.dsp.killactive())
        hl.bind(mainMod .. " + F",      hl.dsp.togglefloating())
        hl.bind(mainMod .. " + P",      hl.dsp.pseudo())
        hl.bind(mainMod .. " + J",      hl.dsp.togglesplit())
        hl.bind(mainMod .. " + M",      hl.dsp.fullscreen())
        hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("uwsm stop"))
        hl.bind("SHIFT + F11",          hl.dsp.exec_cmd("hyprctl dispatch fullscreen 0"))

        -- Navegação de Janelas (setas + hjkl)
        -- Focus
        hl.bind(mainMod .. " + Left",   hl.dsp.movefocus("l"))
        hl.bind(mainMod .. " + Right",  hl.dsp.movefocus("r"))
        hl.bind(mainMod .. " + Up",     hl.dsp.movefocus("u"))
        hl.bind(mainMod .. " + Down",   hl.dsp.movefocus("d"))
        hl.bind(mainMod .. " + CTRL + H", hl.dsp.movefocus("l"))
        hl.bind(mainMod .. " + CTRL + J", hl.dsp.movefocus("d"))
        hl.bind(mainMod .. " + CTRL + K", hl.dsp.movefocus("u"))
        hl.bind(mainMod .. " + CTRL + L", hl.dsp.movefocus("r"))
        -- Move window
        hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.movewindow("l"))
        hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.movewindow("r"))
        hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.movewindow("u"))
        hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.movewindow("d"))
        hl.bind(mainMod .. " + SHIFT + H",     hl.dsp.movewindow("l"))
        hl.bind(mainMod .. " + SHIFT + J",     hl.dsp.movewindow("d"))
        hl.bind(mainMod .. " + SHIFT + K",     hl.dsp.movewindow("u"))
        hl.bind(mainMod .. " + SHIFT + L",     hl.dsp.movewindow("r"))

        -- Workspaces (1-10)
        -- Super+1-0 = switch, Super+Shift+1-0 = move, Super+Alt+1-0 = move silent
        for i = 1, 9 do
          hl.bind(mainMod .. " + " .. i, hl.dsp.workspace(tostring(i)))
          hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.movetoworkspace(tostring(i)))
          hl.bind(mainMod .. " + ALT + " .. i, hl.dsp.movetoworkspacesilent(tostring(i)))
        end
        hl.bind(mainMod .. " + 0", hl.dsp.workspace("10"))
        hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.movetoworkspace("10"))
        hl.bind(mainMod .. " + ALT + 0", hl.dsp.movetoworkspacesilent("10"))

        -- Navegação de Workspaces (relativo + ocupado)
        hl.bind(mainMod .. " + Z",           hl.dsp.workspace("-1"))
        hl.bind(mainMod .. " + X",           hl.dsp.workspace("+1"))
        hl.bind(mainMod .. " + SHIFT + Z",  hl.dsp.workspace("e-1"))
        hl.bind(mainMod .. " + SHIFT + X",  hl.dsp.workspace("e+1"))
        hl.bind(mainMod .. " + mouse_up",    hl.dsp.workspace("e-1"))
        hl.bind(mainMod .. " + mouse_down",  hl.dsp.workspace("e+1"))

        -- Special Workspace (Scratchpad)
        hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace"))
        hl.bind(mainMod .. " + ALT + V",  hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace special"))

        -- Resize Window (repetição contínua)
        -- Usa Super+Alt+Shift+arrows para evitar conflito com movewindow
        hl.bind(mainMod .. " + ALT + SHIFT + Right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 30 0"), { repeating = true })
        hl.bind(mainMod .. " + ALT + SHIFT + Left",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -30 0"), { repeating = true })
        hl.bind(mainMod .. " + ALT + SHIFT + Up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -30"), { repeating = true })
        hl.bind(mainMod .. " + ALT + SHIFT + Down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 30"), { repeating = true })

        -- Column Resize (Dwindle layout)
        hl.bind(mainMod .. " + ALT + Left",  hl.dsp.exec_cmd("hyprctl dispatch layoutmsg colresize -0.1"))
        hl.bind(mainMod .. " + ALT + Right", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg colresize +0.1"))
        hl.bind(mainMod .. " + ALT + H",     hl.dsp.exec_cmd("hyprctl dispatch layoutmsg colresize -0.1"))
        hl.bind(mainMod .. " + ALT + L",     hl.dsp.exec_cmd("hyprctl dispatch layoutmsg colresize +0.1"))
        hl.bind(mainMod .. " + ALT + Down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 50"))
        hl.bind(mainMod .. " + ALT + Up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -50"))
        hl.bind(mainMod .. " + ALT + J",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 50"))
        hl.bind(mainMod .. " + ALT + K",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -50"))

        -- Scrolling Layout (column operations — nativo Ambxst-X)
        hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg promote"))
        hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg togglefit"))
        hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg colresize +conf"))
        hl.bind(mainMod .. " + ALT + SHIFT + Left", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg swapcol l"))
        hl.bind(mainMod .. " + ALT + SHIFT + Right", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg swapcol r"))
        -- Move column to workspace (1-10)
        for i = 1, 10 do
          hl.bind(mainMod .. " + CTRL + ALT + " .. tostring(i), hl.dsp.exec_cmd("hyprctl dispatch layoutmsg movecoltoworkspace " .. tostring(i)))
        end

        -- Lid Switch
        hl.bind("", "switch:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), { lock = true })

        -- Mouse Binds
        hl.bindm(mainMod, "mouse:272", hl.dsp.movewindow())
        hl.bindm(mainMod, "mouse:273", hl.dsp.resizewindow())

        -- Atalhos de Hardware (Media/Volume/Brightness)
        hl.bind("l",  "XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"))
        hl.bind("l",  "XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"))
        hl.bind("l",  "XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"))
        hl.bind("l",  "XF86AudioStop",  hl.dsp.exec_cmd("playerctl stop"))
        hl.bind("le", "XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
        hl.bind("le", "XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"))
        hl.bind("le", "XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        hl.bind("le", "XF86MonBrightnessUp",   hl.dsp.exec_cmd("ambxst brightness +5"))
        hl.bind("le", "XF86MonBrightnessDown", hl.dsp.exec_cmd("ambxst brightness -5"))
        hl.bind("l",  "XF86Calculator",        hl.dsp.exec_cmd("notify-send \"Soon\""))

        -- Ambxst é iniciado pela unidade systemd `ambxst.service`, associada
        -- a graphical-session.target. Não iniciar pelo Lua evita duplicidade
        -- e garante que o ambiente UWSM já tenha sido importado.
      '';
    };
  };
}
