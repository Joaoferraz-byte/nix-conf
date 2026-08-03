# ─── Caelestia Shell ────────────────────────────────────────────────────────
# Integrates the Caelestia Shell desktop shell via the shell-conf flake.
{ self, inputs, ... }: {
  flake.nixosModules.caelestiaShell = { pkgs, lib, config, ... }: {
    # 1. Home Manager module (settings JSON, shell, cli, hyprland integration)
    # We call the exported factory function with the shell-conf flake itself
    home-manager.sharedModules = [
      (inputs.shell-conf.homeManagerModules.default inputs.shell-conf)
    ];
    # 2. Enable Caelestia shell
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
