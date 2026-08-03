# ─── Caelestia Shell ────────────────────────────────────────────────────────
# Integrates the Caelestia Shell desktop shell via the shell-conf flake.
#
# This module:
#   1. Imports shell-conf's NixOS module (enables system level fallback)
#   2. Imports shell-conf's HM module (enables caelestia at user level, settings)
#   3. Keeps pipewire/bluetooth/keyring/audiorelay packages intact
{ self, inputs, ... }: {
  flake.nixosModules.caelestiaShell = { pkgs, lib, config, ... }: {
    # 1. System-level module (if provided by upstream in the future)
    imports = [ inputs.shell-conf.nixosModules.default ];

    # 2. Home Manager module (settings JSON, shell, cli)
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];

    # 3. System packages that were previously in ambxst/dms and are still
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
