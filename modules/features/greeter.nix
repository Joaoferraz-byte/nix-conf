# ─── SDDM Display Manager + Pixie Theme ───────────────────────────────────
# SDDM is the recommended display manager for Hyprland/Wayland.
# We use the pixie-sddm theme (inspired by Google Pixel UI / Material Design 3)
# from the flake input github:xCaptaiN09/pixie-sddm.
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, config, ... }: {
    # ── Enable SDDM with Pixie Theme ───────────────────────────────────────
    environment.systemPackages = [
      inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Required for Hyprland
      theme = "pixie";
      extraPackages = with pkgs; [
        inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.default
        kdePackages.qtmultimedia # Required for video backgrounds/audio
        kdePackages.qtsvg
        kdePackages.qtdeclarative
        kdePackages.qtwayland
      ];
    };

    # ── Fonts: provide Cantarell for the greeter ─────────────────────────
    fonts.packages = with pkgs; [
      cantarell-fonts
      noto-fonts
    ];
  };
}
