# ─── DankMaterialShell ─────────────────────────────────────────────────────
# Integrates the DankMaterialShell desktop shell via the shell-conf flake.
#
# DMS replaces Ambxst entirely. It provides its own systemd user service
# (dms.service) bound to graphical-session.target, and manages its own
# settings JSON, plugin system, and dynamic theming.
#
# This module:
#   1. Imports shell-conf's NixOS module (enables dms at system level)
#   2. Imports shell-conf's HM module (enables dms at user level, settings)
#   3. Adds the sync script for wallpaper assets
#   4. Keeps pipewire/bluetooth/keyring/audiorelay packages intact
{ self, inputs, ... }: {
  flake.nixosModules.dankMaterialShell = { pkgs, lib, config, ... }: {
    # 1. System-level DMS module (polkit, accounts-daemon, geoclue2, power-profiles-daemon)
    imports = [ inputs.shell-conf.nixosModules.default ];

    # 2. Home Manager module (settings JSON, Quickshell, dms.service)
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];

    # 3. System packages that were previously in ambxst.nix and are still
    #    needed for the desktop experience (independent of the shell).
    environment.systemPackages = with pkgs; [
      kitty
      tmux
      fuzzel
      networkmanagerapplet
      blueman
      pavucontrol
      easyeffects
      hicolor-icon-theme
    ];

    # Audio (preserved from old ambxst module — not DMS-specific)
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
