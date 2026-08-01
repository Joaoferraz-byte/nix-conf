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
          },
          misc = {
            force_default_wallpaper = 0,
            disable_hyprland_logo   = true,
          },
        })

        hl.config({ dwindle = { preserve_split = true } })

        -- Binds de recuperação (não conflitam com os defaults do Ambxst).
        local mainMod = "SUPER"
        hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
        hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("systemctl --user restart ambxst.service"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Ambxst é iniciado pela unidade systemd `ambxst.service`, associada
        -- a graphical-session.target. Não iniciar pelo Lua evita duplicidade
        -- e garante que o ambiente UWSM já tenha sido importado.
      '';
    };
  };
}
