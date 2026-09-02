{ inputs, ... }: {
  flake.nixosModules.corePackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh
      jdk21
      jdk8
      maven
      jdt-language-server
      inputs.study-planner.packages.${pkgs.stdenv.hostPlatform.system}.default
      spring-boot-cli
      lombok
      androidStudioPackages.dev

      bitwarden-desktop
      bitwarden-cli
      nautilus
      firefox
      vesktop
      kdePackages.okular
      foliate
      telegram-desktop

      hydralauncher
      heroic

      mpv
      file-roller
      tlp
      btop
      thermald

      kora-icon-theme
      bibata-cursors
      wl-clipboard
      cliphist
      xwayland-satellite
      zip
      gnutar
      gtk3
      gtk4
      adw-gtk3
      libsForQt5.qt5ct
      qt6Packages.qt6ct
      wezterm
      inotify-tools
      keyd
      fastfetch
    ];
  };
}
