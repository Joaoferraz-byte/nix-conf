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
        cliphist
        brightnessctl
        bibata-cursors
        wev
        playerctl
        hyprpicker
        ydotool
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
    
    programs.caelestia.hyprland = {
      enable = true;
      # The userConfig is written to ~/.config/caelestia/hypr-user.lua
      # which is sourced at the end of hyprland.lua by the Caelestia config.
      # This is where user-specific overrides go — window rules, custom
      # keybinds, workspace assignments, etc.
      userConfig = ''
        -- ── Custom User Configuration (hypr-user.lua) ──────────────────
        local vars = require("variables")
        local fn = require("utils.functions")

        -- ── Window Rules ───────────────────────────────────────────────
        -- Vesktop → special:social  (toggle via Super+D)
        hl.window_rule({ match = { class = "vesktop" }, workspace = "special:social silent" })
        -- ZenNotes → special:todo   (toggle via Super+I)
        hl.window_rule({ match = { class = "org.zennotes.ZenNotes" }, workspace = "special:todo silent" })

        -- ── Custom Binds (User Additions) ──────────────────────────────
        -- These complement the upstream keybinds from hyprland/keybinds.lua
        local mainMod = "SUPER"

        -- Terminal e Shell
        hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
        hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("kitty -e tmux"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))
        hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("uwsm stop"))

        -- Note: Most keybinds are defined in the upstream
        -- hypr_upstream/hyprland/keybinds.lua which uses variables.lua
        -- for keybind definitions. The upstream covers:
        --   - Window management (close, float, pseudo, fullscreen, etc.)
        --   - Navigation (focus/move windows, workspaces 1-10, groups)
        --   - Media (play/pause/next/prev, volume, brightness)
        --   - Utilities (screenshot, record, color picker)
        --   - Clipboard and emoji picker
        --   - Special workspaces (social, sysmon, music, communication, todo)
        --   - Apps (terminal, browser, editor, file explorer, audio)
        --   - Session (lock, sleep, launcher, sidebar)
        --
        -- Keybind variable overrides can be done by creating:
        --   ~/.config/caelestia/hypr-vars.lua
        -- which is sourced by hyprland.lua before keybinds are loaded.
      '';
    };

    wayland.systemd.target = "hyprland-session.target";
    wayland.windowManager.hyprland = {
      enable     = true;
      configType = "lua";
      systemd.enable = false;
      settings = {};
      # extraConfig is intentionally empty as we use programs.caelestia.hyprland
    };
  };
}
