{ self, ... }: {
  # ═══════════════════════════════════════════════════════════════════════════
  #  NixOS Module  —  Hyprland compositor + UWSM session management
  # ═══════════════════════════════════════════════════════════════════════════
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
      # ── Hyprland compositor (system-wide) ───────────────────────────────
      programs.hyprland = {
        enable = true;
        # A entrada automática gerada por esta opção não permite passar
        # `-e -D Hyprland` ao UWSM. A sessão declarada acima a substitui.
        withUWSM = false;
        xwayland.enable = true;
      };
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

      services.displayManager.sessionPackages = [ hyprlandUwsmSession ];

      # ═══════════════════════════════════════════════════════════════════════
      # IMPORTANT: The HM hyprland module is NOT used.
      # Caelestia Shell manages the Hyprland Lua config entirely on its own.
      # Enabling wayland.windowManager.hyprland in HM would cause it to:
      #   - Generate hypr/hyprland.lua (overriding Caelestia's config)
      #   - Generate hypr/.luarc.json
      #   - Add hyprland to home.packages (redundant, already in systemPackages)
      #   - Create systemd targets that conflict with UWSM
      #
      # The NixOS module (programs.hyprland.enable = true) handles:
      #   - Installing hyprland system-wide
      #   - SUID wrapper for hyprland
      #   - xdg-desktop-portal-hyprland
      #
      # Caelestia's programs.caelestia.hyprland.enable places:
      #   - hypr/hyprland.lua (entry point)
      #   - hypr/variables.lua
      #   - hypr/hyprland/*.lua (env, general, input, keybinds, etc.)
      #   - hypr/utils/*.lua
      #   - hypr/scheme/*.lua
      #   - caelestia/hypr-user.lua (user overrides)
      # ═══════════════════════════════════════════════════════════════════════
    };

  # ═══════════════════════════════════════════════════════════════════════════
  #  Home Manager Module  —  Cursor + Caelestia Hyprland integration only
  # ═══════════════════════════════════════════════════════════════════════════
  flake.homeManagerModules.hyprland = { pkgs, lib, config, ... }: {
    # ── Cursor ───────────────────────────────────────────────────────────────
    home.pointerCursor = {
      enable  = true;
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    # ── Caelestia Hyprland Integration ───────────────────────────────────────
    # programs.caelestia.hyprland.enable places the Caelestia Lua files under
    # ~/.config/hypr/ (hyprland.lua, variables.lua, hyprland/*.lua, etc.)
    # and the userConfig into ~/.config/caelestia/hypr-user.lua.
    #
    # This is wrapped in programs.caelestia.enable (from caelestia-shell.nix),
    # so it only activates when the Caelestia shell is enabled.
    programs.caelestia.hyprland = {
      enable = true;
      userConfig = ''
        -- ── Custom User Configuration (hypr-user.lua) ──────────────────
        local vars = require("variables")
        local fn = require("utils.functions")

        -- ── Window Rules ───────────────────────────────────────────────
        hl.window_rule({ match = { class = "vesktop" }, workspace = "special:social silent" })
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

    # ── Wayland session target ───────────────────────────────────────────────
    # This tells the Caelestia systemd service when to start.
    # It does NOT activate the HM hyprland module.
    # Under UWSM, the standard target is graphical-session.target.
    wayland.systemd.target = "graphical-session.target";
  };
}
