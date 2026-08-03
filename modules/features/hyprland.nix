{ self, ... }: {
  # ── NixOS Module ────────────────────────────────────────────────────────
  flake.nixosModules.hyprland = { pkgs, lib, config, ... }:
    let
      # A entrada automática de `withUWSM` inicia o wrapper sem declarar
      # explicitamente o DesktopNames. Em versões afetadas de UWSM/Hyprland
      # isso resulta em XDG_CURRENT_DESKTOP=start-hyprland. Esta entrada é a
      # única sessão UWSM local e preserva `Hyprland` em toda a sessão.
      hyprlandUwsmSession = pkgs.writeTextFile {
        name = "hyprland-uwsm";
        destination = "/share/wayland-sessions/hyprland-uwsm.desktop";
        text = ''
          [Desktop Entry]
          Name=Hyprland (UWSM)
          Comment=Hyprland compositor managed by UWSM
          Exec=${lib.getExe config.programs.uwsm.package} start -F -e -D Hyprland -- /run/current-system/sw/bin/start-hyprland
          Type=Application
          DesktopNames=Hyprland
          Keywords=hyprland;wayland;compositor;
        '';
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
        })

        -- General
        hl.config({
          general = {
            layout = "dwindle",
            gaps_in = 5,
            gaps_out = 10,
            border_size = 2,
          },
        })

        -- Decoration
        hl.config({
          decoration = {
            rounding = 15,
            shadow = {
              enabled = true,
              range = 15,
              render_power = 4,
            },
            blur = {
              enabled = true,
              size = 8,
              passes = 2,
              xray = false,
            },
          },
        })

        -- Misc
        hl.config({
          misc = {
            force_default_wallpaper = 0,
            disable_hyprland_logo   = true,
          },
        })

        -- Dwindle layout
        hl.config({ dwindle = { preserve_split = true } })

        -- Binds de recuperação e nativos (garantem funcionalidade básica se o shell falhar).
        local mainMod = "SUPER"

        -- Terminal e Shell
        hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
        hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("kitty -e tmux"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Caelestia: launcher e UI
        hl.bind("SUPER_L", hl.dsp.global("caelestia:launcher"), { release = true })
        hl.bind("CTRL + ALT + Delete", hl.dsp.global("caelestia:session"))
        hl.bind(mainMod .. " + N", hl.dsp.global("caelestia:sidebar"))
        hl.bind("CTRL + ALT + C", hl.dsp.global("caelestia:clearNotifs"), { locked = true })
        hl.bind(mainMod .. " + K", hl.dsp.global("caelestia:showall"))
        hl.bind(mainMod .. " + L", hl.dsp.global("caelestia:lock"))
        hl.bind(mainMod .. " + ALT + L", function()
          hl.dispatch(hl.dsp.exec_cmd("caelestia shell -d"))
          hl.dispatch(hl.dsp.global("caelestia:lock"))
        end)

        -- Caelestia: kill/restart do shell (debug)
        hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("qs -c caelestia kill"), { release = true })
        hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("qs -c caelestia kill; sleep .1; caelestia shell -d"), { release = true })

        -- Caelestia: screenshot/gravação
        hl.bind("Print", hl.dsp.exec_cmd("caelestia screenshot"), { locked = true })
        hl.bind(mainMod .. " + SHIFT + S", hl.dsp.global("caelestia:screenshotFreeze"))
        hl.bind(mainMod .. " + SHIFT + ALT + S", hl.dsp.global("caelestia:screenshot"))
        hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("caelestia record"))
        hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("caelestia record -s"))
        hl.bind(mainMod .. " + SHIFT + ALT + R", hl.dsp.exec_cmd("caelestia record -r"))
        hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

        -- Caelestia: clipboard/emoji
        hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
        hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d"))
        hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"))
        hl.bind("CTRL + SHIFT + ALT + V", hl.dsp.exec_cmd('sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"'), { locked = true })

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

        -- Scrolling Layout (column operations)
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
        hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })

        -- Mouse Binds
        hl.bind(mainMod .. " + mouse:272", hl.dsp.movewindow(), { mouse = true })
        hl.bind(mainMod .. " + mouse:273", hl.dsp.resizewindow(), { mouse = true })

        -- Atalhos de Hardware (Media/Volume/Brightness) - Caelestia OSD
        hl.bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), { locked = true })
        hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), { locked = true })
        hl.bind("XF86AudioPlay", hl.dsp.global("caelestia:mediaToggle"), { locked = true })
        hl.bind("XF86AudioPause", hl.dsp.global("caelestia:mediaToggle"), { locked = true })
        hl.bind("XF86AudioNext", hl.dsp.global("caelestia:mediaNext"), { locked = true })
        hl.bind("XF86AudioPrev", hl.dsp.global("caelestia:mediaPrev"), { locked = true })
        hl.bind("XF86AudioStop", hl.dsp.global("caelestia:mediaStop"), { locked = true })
        
        -- Volume (wpctl nativo)
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
        hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
        hl.bind("XF86Calculator",        hl.dsp.exec_cmd("notify-send \"Soon\""))
      '';
    };
  };
}
