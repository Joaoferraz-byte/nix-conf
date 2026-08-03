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
      userConfig = ''
        -- ── Custom User Configuration (hypr-user.lua) ──────────────────
        local vars = require("variables")
        local fn = require("utils.functions")

        -- ── Window Rules ───────────────────────────────────────────────
        -- Vesktop → special:social  (toggle via Super+D)
        hl.window_rule({ match = { class = "vesktop" }, workspace = "special:social silent" })
        -- ZenNotes → special:todo   (toggle via Super+I)
        hl.window_rule({ match = { class = "org.zennotes.ZenNotes" }, workspace = "special:todo silent" })

        -- ── Custom Binds ───────────────────────────────────────────────
        local mainMod = "SUPER"

        -- Terminal e Shell
        hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
        hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("kitty -e tmux"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- ── Full Shortcut Coverage (Merged from Upstream) ──────────────
        -- Many of these are already in the main hyprland.lua, 
        -- but we ensure coverage here if needed.

        -- System
        hl.bind(mainMod .. " + C",      hl.dsp.window.close())
        hl.bind(mainMod .. " + F",      hl.dsp.window.float())
        hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
        hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
        hl.bind(mainMod .. " + M",      hl.dsp.window.fullscreen())
        hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("uwsm stop"))

        -- Navigation
        for _, dir in ipairs({ "left", "right", "up", "down" }) do
          hl.bind(mainMod .. " + " .. dir:sub(1,1):upper() .. dir:sub(2), hl.dsp.focus({ direction = dir }))
          hl.bind(mainMod .. " + SHIFT + " .. dir:sub(1,1):upper() .. dir:sub(2), hl.dsp.window.move({ direction = dir }))
        end

        -- Workspaces (1-10)
        for i = 1, 9 do
          hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
        end
        hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
        hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

        -- Special Workspace Toggles
        hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("caelestia toggle social"))
        hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("caelestia toggle todo"))
        hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
        
        -- Media/Volume (handled by upstream hyprland.lua, but kept for clarity)
      '';
    };

    wayland.windowManager.hyprland = {
      enable     = true;
      configType = "lua";
      systemd.enable = false;
      settings = {};
      # extraConfig is intentionally empty as we use programs.caelestia.hyprland
    };
  };
}
