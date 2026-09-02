{ inputs, ... }: {
  flake.nixosModules.corePackages = { pkgs, ... }: {
    nixpkgs.config.permittedInsecurePackages = [
      "idea-oss-2025.3.4"
    ];

    environment.systemPackages = with pkgs; [
      git
      gh
      jdk21
      jdk8
      maven
      inputs.study-planner.packages.${pkgs.stdenv.hostPlatform.system}.default
      spring-boot-cli
      lombok
      androidStudioPackages.dev
      jetbrains.idea-oss

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
