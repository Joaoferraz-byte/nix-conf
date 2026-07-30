# ─── SDDM Display Manager + Noctalia Theme ────────────────────────────────
# SDDM is the display manager with the Noctalia theme for the login screen.
# The sddm-noctalia-theme (github:ClementFombonne/sddm-noctalia-theme)
# provides an official NixOS module that handles packaging, dependencies, and
# theme configuration declaratively.
#
# NOTE: This module uses SDDM + Noctalia theme. The greeter service was
# previously greetd+regreet (older setup). Now migrated to SDDM.
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, config, ... }: {

    # ── Enable SDDM with Noctalia Theme ───────────────────────────────────
    imports = [ inputs.sddm-noctalia.nixosModules.default ];

    services.displayManager.sddm.noctalia = {
      enable = true;

      # Custom wallpaper: use the Noctalia purple/violet icon as background
      background = "${self}/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg";

      # Color scheme matching the Noctalia desktop
      colorScheme = "Noctalia-default";
      darkMode = true;

      # Typography: Cantarell (already used in the system)
      fontFamily = "Cantarell";

      # Clock: digital, 24h (PT-BR locale)
      clockStyle = "digital";

      # Scaling: comfortable for 1080p displays
      scaling = {
        font = 1.0;
        radius = 1.0;
        iRadius = 1.0;
        screenRadius = 1.0;
        scale = 1.0;
        animationSpeed = 1.0;
      };
    };

    # ── Wayland support for SDDM (required by assertion) ──────────────────
    # Hyprland is a Wayland-only compositor; SDDM must run in Wayland mode.
    services.displayManager.sddm.wayland.enable = true;

    # ── Fonts: provide Cantarell for the greeter ─────────────────────────
    # SDDM Noctalia theme needs fonts available in the system package store.
    fonts.packages = with pkgs; [
      cantarell-fonts
      noto-fonts
    ];

  };
}
