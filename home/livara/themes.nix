{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.kora-icon-theme
    pkgs.bibata-cursors
  ];

  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  # GTK3/GIO owns the Nautilus bookmark contract. Do not set gtk-theme here:
  # DMS writes the wallpaper-derived gtk.css dynamically.
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.kora-icon-theme;
      name = "Kora";
    };
    gtk3 = {
      enable = true;
      bookmarks = [
        "file://${config.xdg.userDirs.desktop} Desktop"
        "file://${config.xdg.userDirs.documents} Documents"
        "file://${config.xdg.userDirs.download} Downloads"
        "file://${config.xdg.userDirs.pictures} Pictures"
        "file://${config.home.homeDirectory}/Projetos Projects"
        "file://${config.home.homeDirectory}/Vault Vault"
      ];
    };
    gtk4.enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Kora";
    };
    "org/gnome/desktop/media-handling" = {
      automount = true;
      automount-open = true;
    };
  };

  home.sessionVariables = {
    # DMS owns GTK_THEME/gtk.css dynamically from the active Matugen palette.
    GTK_ICON_THEME = "Kora";
    QT_ICON_THEME = "Kora";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
  };
}
