{ config, pkgs, ... }:
let
  # Nautilus requests symbolic names that are not present in every Kora
  # release (notably starred-symbolic). Keep Kora as the visual owner and
  # add only freedesktop-compatible aliases; do not draw a second icon theme.
  livaraKoraIconTheme = pkgs.runCommand "livara-kora-icon-theme" { } ''
    theme="$out/share/icons/Livara-Kora"
    mkdir -p "$theme/places/symbolic"
    cat > "$theme/index.theme" <<'EOF'
[Icon Theme]
Name=Livara Kora
Comment=Kora with Nautilus symbolic compatibility aliases
Inherits=Kora
Directories=places/symbolic

[places/symbolic]
Context=Places
Size=16
MinSize=8
MaxSize=512
Type=Scalable
EOF
    ln -s "${pkgs.kora-icon-theme}/share/icons/Kora/emblems/symbolic/emblem-favorite-symbolic.svg" \
      "$theme/places/symbolic/starred-symbolic.svg"
    ln -s "${pkgs.kora-icon-theme}/share/icons/Kora/places/symbolic/user-trash-symbolic.svg" \
      "$theme/places/symbolic/user-trash-symbolic.svg"
    ln -s "${pkgs.kora-icon-theme}/share/icons/Kora/places/symbolic/user-trash-symbolic.svg" \
      "$theme/places/symbolic/user-trash-full-symbolic.svg"
  '';
in
{
  home.packages = [
    pkgs.kora-icon-theme
    livaraKoraIconTheme
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
      package = livaraKoraIconTheme;
      name = "Livara-Kora";
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
      icon-theme = "Livara-Kora";
    };
    "org/gnome/desktop/media-handling" = {
      automount = true;
      automount-open = true;
    };
  };

  home.sessionVariables = {
    # DMS owns GTK_THEME/gtk.css dynamically from the active Matugen palette.
    GTK_ICON_THEME = "Livara-Kora";
    QT_ICON_THEME = "Livara-Kora";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
  };
}
