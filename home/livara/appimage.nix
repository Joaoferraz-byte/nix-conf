{ pkgs, ... }:
let
  firejailAppimage = pkgs.writeShellScript "livara-firejail-appimage" ''
    set -Eeuo pipefail

    appimage="''${1:-}"
    shift || true
    if [ -z "$appimage" ]; then
      printf '%s\n' 'Usage: livara-firejail-appimage /path/to/app.AppImage [args...]' >&2
      exit 64
    fi
    if [ ! -f "$appimage" ]; then
      printf 'AppImage not found: %s\n' "$appimage" >&2
      exit 66
    fi

    # Nautilus can pass a downloaded AppImage without the executable bit.
    # Grant it only to the file explicitly selected by the user; never modify
    # a store path or silently search/execute another file.
    if [ ! -x "$appimage" ]; then
      if [ -w "$appimage" ]; then
        chmod u+x "$appimage"
      else
        printf 'AppImage is not executable and is not writable: %s\n' "$appimage" >&2
        exit 126
      fi
    fi

    # Keep the selected AppImage as the final command argument. `--appimage`
    # selects Firejail's AppImage path; `--` terminates Firejail options.
    exec ${pkgs.firejail}/bin/firejail \
      --quiet \
      --noprofile \
      --net=none \
      --caps.drop=all \
      --seccomp \
      --appimage \
      -- "$appimage" "$@"
  '';
in
{
  xdg.desktopEntries.firejail-appimage = {
    name = "Firejail AppImage";
    comment = "Run a selected AppImage in a Firejail sandbox";
    exec = "${firejailAppimage} %f";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    mimeType = [ "application/vnd.appimage" ];
  };

  xdg.mimeApps.defaultApplications = {
    "application/vnd.appimage" = [ "firejail-appimage.desktop" ];
  };
}
