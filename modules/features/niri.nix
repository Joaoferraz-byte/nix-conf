{ self, inputs, ... }: {
  # niri-flake exposes no Home Manager module for niri settings and its NixOS
  # module has no `programs.niri.settings` option, so the compositor settings
  # and keybinds are written as a plain config.kdl file via Home Manager
  # (home/livara/home.nix). The NixOS module just turns the compositor on and
  # installs the helper packages.
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
