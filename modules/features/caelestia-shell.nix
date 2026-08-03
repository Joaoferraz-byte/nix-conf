# ─── Caelestia Shell ────────────────────────────────────────────────────────
# Integrates the Caelestia Shell desktop shell via the shell-conf flake.
#
# This module:
#   1. Imports shell-conf's Home Manager module (provides programs.caelestia options)
#   2. Enables the shell (programs.caelestia.enable = true) — WITHOUT this,
#      the entire programs.caelestia module is a no-op.
#   3. Enables the CLI (programs.caelestia.cli.enable = true)
#   4. Provides mutable settings so the UI can save changes
#   5. Keeps pipewire/bluetooth/keyring packages intact
{ self, inputs, ... }: {
  flake.nixosModules.caelestiaShell = { pkgs, lib, config, ... }: {
    # 1. Home Manager module (settings JSON, shell, cli, hyprland integration)
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];
    # 2. Enable Caelestia shell — THIS IS THE KEY OPTION
    #    Without this, the entire programs.caelestia module is a no-op
    #    (everything is wrapped in lib.mkIf cfg.enable).
    home-manager.users.livara.programs.caelestia = {
      enable = true;
      mutableSettings = true;  # Allow the GUI to persist settings changes
      cli.enable = true;       # Install caelestia-cli alongside the shell
    };

    # 3. System packages that were previously in ambxst/dms and are still
    #    needed for the desktop experience (independent of the shell).
    environment.systemPackages = with pkgs; [
      kitty
      tmux
      fuzzel
      # Caelestia Shell provides native network, bluetooth, and audio controls.
      # networkmanagerapplet, blueman, pavucontrol removed as redundant.
      easyeffects
      hicolor-icon-theme
    ];

    # Audio (preserved from old modules)
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    services.blueman.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.gnome.gnome-keyring.enable = lib.mkDefault true;
  };
}
