{ ... }: {
  flake.nixosModules.corePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh
      nautilus
      brave
      vesktop
      kdePackages.okular
      foliate
      obsidian
      hydralauncher
      heroic
      jdk21
      jdk8
      jdt-language-server
      spring-boot-cli
      lombok
      file-roller
      tlp
      powertop
      thermald
      code-cursor

      # Niri + DMS dependencies
      kora-icon-theme
      bibata-cursors
      wl-clipboard
      cliphist
      xwayland-satellite
      catppuccin-gtk
      catppuccin-kvantum
      catppuccin-cursors
      wezterm
    ];
  };
}
