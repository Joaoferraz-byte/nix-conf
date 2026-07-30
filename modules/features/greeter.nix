# ─── SDDM Display Manager + Astronaut Theme ────────────────────────────────
# SDDM is the recommended display manager for Hyprland/Wayland.
# We use the community-maintained sddm-astronaut package for a modern look
# that matches the Ambxst-X aesthetic.
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, config, ... }: {
    # ── Enable SDDM with Astronaut Theme ───────────────────────────────────
    # We use the package from nixpkgs (sddm-astronaut) and configure it
    # as per the NixOS wiki.
    environment.systemPackages = with pkgs; [
      sddm-astronaut
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Required for Hyprland
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs; [
        sddm-astronaut
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
