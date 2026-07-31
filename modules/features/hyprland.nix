{ self, inputs, ... }: {
  # ── NixOS Module ────────────────────────────────────────────────────────
  flake.nixosModules.hyprland = { pkgs, lib, ... }: {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    # pkgs.hyprland já inclui hyprland-uwsm.desktop via passthru.providedSessions.
    # Declarar waylandCompositors.hyprland aqui criaria um segundo entry conflitante.

    environment.systemPackages = with pkgs; [
      grim
      slurp
      wl-clipboard
      brightnessctl
      bibata-cursors
      wev
    ];

    home-manager.sharedModules = [
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
        hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("ambxst reload"))
        hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("uwsm stop"))

        -- Inicia o Ambxst uma única vez por sessão.
        hl.on("hyprland.start", function()
          hl.exec_cmd("ambxst")
        end)
      '';
    };
  };
}
