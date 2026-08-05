{ ... }: {
  flake.nixosModules.corePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Development
      git
      gh
      jdk21
      jdk8
      jdt-language-server
      spring-boot-cli
      lombok

      # Personal
      nautilus
      firefox
      vesktop
      kdePackages.okular
      foliate
      obsidian
      tauon
      telegram-desktop

      # Games
      hydralauncher
      heroic

      # Utilities
      mpv
      nomacs
      file-roller
      tlp
      btop
      thermald

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
