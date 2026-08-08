# ─── Caelestia Shell ────────────────────────────────────────────────────────
# Integrates the Caelestia Shell desktop shell via the shell-conf flake.
# The shell-conf Home Manager module is imported directly in the per-user
# Home Manager configuration (home/livara/home.nix); duplicating it here in
# home-manager.sharedModules caused a double application of its options.
{ self, inputs, ... }: {
  flake.nixosModules.caelestiaShell = { pkgs, lib, config, ... }: {
    # Caelestia Home Manager module (declares programs.caelestia options)
    home-manager.sharedModules = [ inputs.shell-conf.homeManagerModules.caelestia ];
    # Enable Caelestia shell
    home-manager.users.livara.programs.caelestia = {
      enable = true;
      mutableSettings = true;
      cli.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kitty tmux fuzzel easyeffects hicolor-icon-theme
      polkit_gnome geoclue2 gammastep
    ];

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
