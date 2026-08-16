{ ... }: {
  flake.nixosModules.corePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh
      jdk21
      jdk8
      jdt-language-server
      spring-boot-cli
      lombok

      _1password-gui
      nautilus
      firefox
      vesktop
      kdePackages.okular
      foliate
      tauon
      telegram-desktop

      hydralauncher
      heroic

      mpv
      nomacs
      file-roller
      tlp
      btop
      thermald

      kora-icon-theme
      bibata-cursors
      wl-clipboard
      cliphist
      xwayland-satellite
      adw-gtk3
      catppuccin-gtk
      catppuccin-kvantum
      catppuccin-cursors
      wezterm
      inotify-tools
      fastfetch
    ];
  };
}
