{ inputs, ... }: {
  flake.nixosModules.corePackages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages =
        with pkgs;
        [
          git
          gh
          jdk21
          jdk8
          maven
          spring-boot-cli
          lombok
          androidStudioPackages.dev
          manim
          manim-slides

          bitwarden-desktop
          bitwarden-cli
          nautilus
          firefox
          vesktop
          kdePackages.okular
          foliate
          telegram-desktop
          localsend
          kdePackages.kdenlive

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
        ]
        ++ lib.optionals config.desktop.profile.studyPlanner [
          inputs.study-planner.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
    };
}
