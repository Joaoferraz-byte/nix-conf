# ─── SDDM Display Manager + Noctalia Theme ────────────────────────────────
# SDDM is the recommended display manager for Noctalia (used by KDE/Qt-based
# shells). The sddm-noctalia-theme (github:ClementFombonne/sddm-noctalia-theme)
# provides an official NixOS module that handles packaging, dependencies, and
# theme configuration declaratively.
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

    # ── Fonts: provide Cantarell for the greeter ─────────────────────────
    # SDDM Noctalia theme needs fonts available in the system package store.
    fonts.packages = with pkgs; [
      cantarell-fonts
      noto-fonts
    ];

  };
}
