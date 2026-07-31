# ─── Hyprland Wayland Compositor ───────────────────────────────────────────
# Exporta dois módulos distintos:
#   1. flake.nixosModules.hyprland  — NixOS: pacotes de sistema, programas.hyprland
#   2. flake.homeManagerModules.hyprland — HM: configuração do usuário
#
# NOTA CRÍTICA: homeManagerModules deve ficar no nível do flake (top-level),
# NUNCA dentro de perSystem. No flake-parts, perSystem define atributos
# por-arquitetura (packages, devShells, apps, checks), enquanto
# homeManagerModules/nixosModules/overlays/templates são saídas globais do flake.
{ self, inputs, ... }: {
  # ── NixOS Module ────────────────────────────────────────────────────────
  # Habilita componentes críticos: polkit, xdg-desktop-portal-hyprland,
  # drivers gráficos, fontes, dconf, xwayland e entrada no Display Manager.
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland = {
      enable = true;
      withUWSM = true; # Recommended for systemd integration
      xwayland.enable = true;
    };

    # ── UWSM Session Entry ───────────────────────────────────────────────
    # binPath DEVE apontar para start-hyprland (não Hyprland direto).
    # start-hyprland é o wrapper oficial que seta XDG vars, portals,
    # suporte a Electron e screen sharing. Lançar Hyprland direto causa
    # warning + emergency lock do UWSM.
    # prettyName curto evita overflow no SDDM session selector.
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
      # xwayland-satellite is not needed for Hyprland as it uses Xwayland directly
    ];

    # Disable Home Manager's systemd integration since UWSM handles it
    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.systemd.enable = false;
      }
    ];
  };

  # ── Home Manager Module ─────────────────────────────────────────────────
  # Configuração do usuário: keybinds, monitor, window rules, etc.
  # Este módulo deve ser importado no home-manager.sharedModules do host.
  flake.homeManagerModules.hyprland = { config, ... }: {
    wayland.windowManager.hyprland = {
      enable = true;

      # We use UWSM via the NixOS module, so we disable the HM systemd integration
      systemd.enable = false;

      settings = {
        # ── Monitor Setup ──────────────────────────────────────────────
        monitor = ",preferred,auto,1";

        # ── Startup ─────────────────────────────────────────────────
        # The Ambxst wrapper initializes axctl and Quickshell.
        # UWSM requires exec-once to be properly formatted.
        exec-once = [
          "ambxst"
        ];

        # ── Source Ambxst-X Config ──────────────────────────────────
        # As required by Ambxst-X docs, source its generated config block.
        source = "~/.local/share/ambxst/hyprland.conf";

        # ── Input ───────────────────────────────────────────────────
        input = {
          kb_layout = "br";
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
          };
        };

        # ── Layout & Appearance ──────────────────────────────────────
        # Note: Gaps and blur are managed by Ambxst-X (compositor.json).
        # We only define things not covered by Ambxst-X here to avoid conflicts.
        general = {
          layout = "dwindle";
        };

        decoration = {
          # Handled by Ambxst-X, leaving empty to avoid overriding
        };

        # ── Window Rules ────────────────────────────────────────────
        windowrulev2 = [
          # Quickshell rules
          "noblur, class:^(quickshell)$"
          "noshadow, class:^(quickshell)$"
          "noborder, class:^(quickshell)$"
          "norounding, class:^(quickshell)$"
        ];

        # ── Keybinds ────────────────────────────────────────────────
        "$mod" = "SUPER";

        bind = [
          # Applications
          "$mod, Return, exec, alacritty"
          "$mod, O, exec, obsidian"
          "$mod, W, exec, brave"
          "$mod, E, exec, nautilus"

          # Window Management
          "$mod, Q, killactive,"
          "$mod, F, fullscreen, 1" # maximize
          "$mod SHIFT, F, fullscreen, 0"
          "$mod SHIFT, V, togglefloating,"

          # Focus and Movement
          "$mod, Left, movefocus, l"
          "$mod, Right, movefocus, r"
          "$mod, Up, movefocus, u"
          "$mod, Down, movefocus, d"
          "$mod SHIFT, Left, movewindow, l"
          "$mod SHIFT, Right, movewindow, r"
          "$mod SHIFT, Up, movewindow, u"
          "$mod SHIFT, Down, movewindow, d"

          # Workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod, Page_Down, workspace, e+1"
          "$mod, Page_Up, workspace, e-1"

          # Screenshot
          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
          "$mod, Print, exec, grim - | wl-copy"

          # Quit
          "$mod SHIFT, E, exit,"
        ];

        # Audio and Brightness (using binde for repeating keys)
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
          ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ];

        bindl = [
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ];
      };
    };
  };
}
