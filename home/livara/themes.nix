{ pkgs, ... }:
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

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Kora";
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
