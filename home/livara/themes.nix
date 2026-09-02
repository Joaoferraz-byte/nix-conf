{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;

  # Livara-Kora is the Kora icon theme with a stable local places directory.
  # The main folder-view icons are assigned by GIO named metadata; bookmarks
  # remain owned by Nautilus itself.
  #
  # Kora provides the native full-colour and symbolic place shapes. We copy
  # both directories locally so the main Nautilus view does not depend on a
  # second Inherits lookup under /nix/store.
  livaraKoraIconTheme = pkgs.runCommand "livara-kora-icon-theme" { } ''
    theme="$out/share/icons/Livara-Kora"
    kora="${pkgs.kora-icon-theme}/share/icons/kora"

    # ---- 1. Copy ALL of Kora's places/ (full-colour + symbolic) ----
      # This makes Livara-Kora self-consistent: every standard place icon
    # resolves within the theme itself. Copy both variants so custom folder
    # identities work in normal views and symbolic bookmark/sidebar views.
    mkdir -p "$theme/places"
    cp -r "$kora/places/scalable" "$theme/places/scalable"
    cp -r "$kora/places/symbolic" "$theme/places/symbolic"
    chmod -R u+w "$theme/places/scalable" "$theme/places/symbolic"
    rm -f "$theme/places/scalable/folder-public.svg" "$theme/places/symbolic/folder-public-symbolic.svg"

    # ---- 2. index.theme — declare both place directories ----
    cat > "$theme/index.theme" <<'EOF'
[Icon Theme]
Name=Livara Kora
Comment=Kora complete places + custom Livara symbolic folder icons
Inherits=kora
FollowsColorScheme=true
Directories=places/scalable,places/symbolic

[places/scalable]
Context=Places
Size=48
MinSize=8
MaxSize=512
Type=Scalable

[places/symbolic]
Context=Places
Size=16
MinSize=8
MaxSize=512
Type=Scalable
EOF

    # ---- 3. starred-symbolic alias ----
    # Kora ships emblem-favorite-symbolic while GTK consumers may request
    # starred-symbolic. Symlink it into the symbolic places dir.
    ln -sf "$kora/emblems/symbolic/emblem-favorite-symbolic.svg" \
      "$theme/places/symbolic/starred-symbolic.svg"

    # ---- 4. Special symbolic bookmark icons ----
    # Kora ships full-colour scalable icons for these places.  Pictures also
    # has a native symbolic variant; for the other custom folders we draw
    # purpose-specific symbolic shapes that match Kora's icon language rather
    # than using a generic folder outline with a glyph.
    #
    # Kora symbolic style (confirmed from source):
    #   viewBox="0 0 36 36"
    #   fill="currentColor" class="ColorScheme-Text"
    #   fill-opacity .71 (primary) / .5 (secondary) / .4 / .15 (tertiary)
    #   Purpose-specific shape, not a folder outline

    # folder-applications-symbolic — a 3×3 app grid (the freedesktop
    # "applications" concept).  Drawn as a grid of rounded squares, the
    # canonical symbolic for an app launcher / applications folder.
    cat > "$theme/places/symbolic/folder-applications-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
 <defs>
  <style id="current-color-scheme" type="text/css">
   .ColorScheme-Text { color:#dfdfdf; } .ColorScheme-Highlight { color:#4285f4; }
  </style>
 </defs>
 <g fill="currentColor" class="ColorScheme-Text">
  <rect x="8" y="8" width="6" height="6" rx="1.2" fill-opacity=".71"/>
  <rect x="15" y="8" width="6" height="6" rx="1.2" fill-opacity=".5"/>
  <rect x="22" y="8" width="6" height="6" rx="1.2" fill-opacity=".4"/>
  <rect x="8" y="15" width="6" height="6" rx="1.2" fill-opacity=".5"/>
  <rect x="15" y="15" width="6" height="6" rx="1.2" fill-opacity=".71"/>
  <rect x="22" y="15" width="6" height="6" rx="1.2" fill-opacity=".5"/>
  <rect x="8" y="22" width="6" height="6" rx="1.2" fill-opacity=".4"/>
  <rect x="15" y="22" width="6" height="6" rx="1.2" fill-opacity=".5"/>
  <rect x="22" y="22" width="6" height="6" rx="1.2" fill-opacity=".71"/>
 </g>
</svg>
SVG

    # folder-private-symbolic — a padlock, the universal symbolic for
    # private/encrypted/vault.  Drawn as a lock body + shackle, matching
    # Kora's system-lock-screen-symbolic visual weight.
    cat > "$theme/places/symbolic/folder-private-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
 <defs>
  <style id="current-color-scheme" type="text/css">
   .ColorScheme-Text { color:#dfdfdf; } .ColorScheme-Highlight { color:#4285f4; }
  </style>
 </defs>
 <path style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".5" d="M18 4a7 7 0 0 0-7 7v4h-2a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h18a2 2 0 0 0 2-2V17a2 2 0 0 0-2-2h-2v-4a7 7 0 0 0-7-7zm-4 11v-4a4 4 0 0 1 8 0v4z"/>
 <path style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".71" d="M9 15h2v-4a7 7 0 0 1 14 0v4h2a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V17a2 2 0 0 1 2-2zm5 0h8v-4a4 4 0 0 0-8 0z"/>
 <circle style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".15" cx="18" cy="23" r="2.5"/>
</svg>
SVG

    # folder-projects-symbolic — a clipboard with a checkmark, the symbolic
    # for a project/task folder.  Drawn as a clipboard (board + clip) with
    # a checkmark, echoing Kora's task/checklist symbology.
    cat > "$theme/places/symbolic/folder-projects-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
 <defs>
  <style id="current-color-scheme" type="text/css">
   .ColorScheme-Text { color:#dfdfdf; } .ColorScheme-PositiveText { color:#4caf50; }
  </style>
 </defs>
 <path style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".71" d="M14 4a2 2 0 0 0-2 2v1H9a2 2 0 0 0-2 2v21a2 2 0 0 0 2 2h18a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3V6a2 2 0 0 0-2-2zm0 2h8v2h-8z"/>
 <path style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".5" d="M9 9h3v1a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V9h3v21H9z"/>
 <path style="fill:none;stroke:currentColor;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round" class="ColorScheme-Text" fill-opacity=".71" d="M13 19l3 3 6-6"/>
</svg>
SVG

    # Restored historical Wallpapers bookmark icon: an image frame with a
    # sun/mountain motif. It is distinct from Pictures' native symbolic icon.
    cat > "$theme/places/symbolic/folder-images-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36">
 <defs>
  <style id="current-color-scheme" type="text/css">
   .ColorScheme-Text { color:#dfdfdf; } .ColorScheme-Highlight { color:#4285f4; }
  </style>
 </defs>
 <path style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".71" d="M6 6h24a2 2 0 0 1 2 2v20a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2zm0 2v20h24V8z"/>
 <circle style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".5" cx="13" cy="14" r="2.5"/>
 <path style="fill:currentColor" class="ColorScheme-Text" fill-opacity=".5" d="M8 26l6-6 3 3 5-5 6 6v2H8z"/>
</svg>
SVG

    # Normal Nautilus navigation uses special full-colour scalable icons.
    for icon in folder-applications folder-private folder-projects folder-pictures folder-image; do
      cp "$kora/places/scalable/$icon.svg" "$theme/places/scalable/$icon.svg"
    done

    # Books and Games use Kora's native full-colour folder artwork. Kora
    # names its native music artwork in the singular; copy it under the
    # plural semantic name used by our GIO metadata mapping. Navigation now
    # uses the exact Kora artwork, while bookmarks remain a separate contract.
    cp "$kora/places/scalable/folder-books.svg" \
      "$theme/places/scalable/folder-books.svg"
    cp "$kora/places/scalable/folder-games.svg" \
      "$theme/places/scalable/folder-games.svg"
    cp "$kora/places/scalable/folder-music.svg" \
      "$theme/places/scalable/folder-musics.svg"

    # The symbolic assets below are the separate sidebar/bookmark contract.
    cat > "$theme/places/symbolic/folder-books-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><path fill="currentColor" fill-opacity=".71" d="M7 7h8l2 3h12v19H7z"/><path fill="currentColor" fill-opacity=".5" d="M13 13h3v12h-3zm5 0h3v12h-3zm5 0h3v12h-3z"/></svg>
SVG
    cat > "$theme/places/symbolic/folder-games-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><path fill="currentColor" fill-opacity=".71" d="M9 13h4l2-3h6l2 3h4a4 4 0 0 1 4 4v8a4 4 0 0 1-4 4h-3l-3-4h-4l-3 4h-3a4 4 0 0 1-4-4v-8a4 4 0 0 1 4-4zm3 5h-2v2h2v2h2v-2h2v-2h-2v-2h-2z"/><circle fill="currentColor" fill-opacity=".5" cx="24" cy="19" r="1.5"/><circle fill="currentColor" fill-opacity=".5" cx="28" cy="23" r="1.5"/></svg>
SVG
    cat > "$theme/places/symbolic/folder-musics-symbolic.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36"><path fill="currentColor" fill-opacity=".71" d="M18 7h10v3h-7v13a4 4 0 1 1-2-3.46V12h9v3h-6v8a4 4 0 1 1-2-3.46z"/></svg>
SVG
  '';

  # GIO stores per-folder named icons in the GVfs metadata database. This is
  # deliberately a user-session unit rather than a build-time mutation: the
  # directories are user data and may not exist during Nix evaluation.
  specialFolderIcons = pkgs.writeShellScript "livara-nautilus-special-folder-icons" ''
    set -u
    gio="${pkgs.glib}/bin/gio"
    failed=0

    for spec in \
      "${home}/Books|folder-books" \
      "${home}/Games|folder-games" \
      "${home}/Musics|folder-musics" \
      "${home}/Fire|folder-applications" \
      "${home}/Vault|folder-private" \
      "${home}/Projects|folder-projects" \
      "${home}/Pictures|folder-pictures" \
      "${home}/Wallpapers|folder-image"; do
      path="''${spec%|*}"
      icon="''${spec##*|}"
      [ -d "$path" ] || continue
      # The historical path sets only the named icon for the actual folder.
      # Nautilus does not currently use this metadata for bookmark rows.
      if ! "$gio" set -t string "$path" metadata::custom-icon-name "$icon"; then
        printf 'Could not set custom icon %s on %s\n' "$icon" "$path" >&2
        failed=1
      fi
    done

    exit "$failed"
  '';
in
{
  home.packages = [
    pkgs.glib
    pkgs.kora-icon-theme
    livaraKoraIconTheme
    pkgs.bibata-cursors
  ];

  systemd.user.services.livara-nautilus-special-folder-icons = {
    Unit = {
      Description = "Apply semantic Kora icons to Livara folders";
      # Canonical niri pattern: order on graphical-session.target, pull in
      # via niri.service.  See the session ownership comment in home.nix.
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${specialFolderIcons}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "niri.service" ];
  };

  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 26;
  };

  # Nautilus' patched bookmark model reads this URI -> symbolic-icon map.
  # It affects only the sidebar; normal folder navigation keeps its own
  # full-colour `metadata::custom-icon-name` path above.
  home.file.".config/nautilus/bookmark-icons".text = ''
    # URI<TAB>symbolic icon name
    file://${home}/Books	folder-books-symbolic
    file://${home}/Games	folder-games-symbolic
    file://${home}/Musics	folder-musics-symbolic
    file://${home}/Projects	folder-projects-symbolic
    file://${home}/Vault	folder-private-symbolic
    file://${home}/Fire	folder-applications-symbolic
    file://${home}/Pictures	folder-pictures-symbolic
    file://${home}/Wallpapers	folder-images-symbolic
  '';

  # GTK3 owns the bookmark URI list; the patched Nautilus owner supplies the
  # independent symbolic icons from the map above.
  # Do not set gtk-theme here:
  # Noctalia writes the wallpaper-derived GTK CSS dynamically.
  gtk = {
    enable = true;
    iconTheme = {
      package = livaraKoraIconTheme;
      name = "Livara-Kora";
    };
    gtk3 = {
      enable = true;
      bookmarks = [
        "file://${config.xdg.userDirs.documents} Documents"
        "file://${config.xdg.userDirs.download} Downloads"
        "file://${home}/Pictures Pictures"
        "file://${home}/Wallpapers Wallpapers"
        "file://${config.home.homeDirectory}/Games Games"
        "file://${config.home.homeDirectory}/Projects Projects"
        "file://${config.home.homeDirectory}/Vault Vault"
        "file://${config.home.homeDirectory}/Fire Fire"
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
    # Noctalia owns the wallpaper-derived GTK palette; keep only stable session
    # variables here.
    GTK_ICON_THEME = "Livara-Kora";
    QT_ICON_THEME = "Livara-Kora";
  };
}
