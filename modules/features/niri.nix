{ self, inputs, ... }: {
  # Compositor settings and keybinds are now managed by the shell-conf
  # `programs.niri.settings` Home Manager module (imported transitively by
  # home/livara/home.nix via shell-conf.homeManagerModules.default).
  # This NixOS module just turns the compositor on and installs the helper
  # packages.
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri.enable = true;
    environment.systemPackages = with pkgs; [
      xwayland-satellite
      swaybg
      waybar
      fuzzel
      kitty
      dunst
      libnotify
    ];
  };
}
