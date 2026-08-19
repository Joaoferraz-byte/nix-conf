{ ... }:
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Kora";
    };
  };

  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    GTK_ICON_THEME = "Kora";
    QT_ICON_THEME = "Kora";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };
}
