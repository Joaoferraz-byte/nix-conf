{ pkgs, ... }:
let
  firejailAppimage = pkgs.writeShellScriptBin "livara-firejail-appimage" ''
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

    firejail_bin=/run/wrappers/bin/firejail
    [[ -x "$firejail_bin" ]] || {
      printf '%s\n' 'Firejail wrapper is unavailable: rebuild with programs.firejail.enable = true' >&2
      exit 69
    }

    # On NixOS, Firejail's native `--appimage` path mounts the image but
    # launches its generic /bin/bash and dynamic linker directly. Generic
    # AppImages then fail because NixOS does not provide the traditional FHS.
    # Use the official NixOS appimage-run/bwrap compatibility layer as the
    # inner runner, and keep Firejail as the outer network/capability sandbox.
    # Do not enable Firejail seccomp here: appimage-run needs bwrap namespace
    # operations (mount/pivot_root) to construct the FHS environment.
    exec "$firejail_bin" \
      --quiet \
      --noprofile \
      --net=none \
      --caps.drop=all \
      -- ${pkgs.appimage-run}/bin/appimage-run "$appimage" "$@"
  '';
in
{
  home.packages = [ firejailAppimage ];

  xdg.desktopEntries.firejail-appimage = {
    name = "Firejail AppImage";
    comment = "Run a selected AppImage with NixOS appimage-run inside Firejail";
    exec = "${firejailAppimage}/bin/livara-firejail-appimage %f";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    mimeType = [ "application/vnd.appimage" ];
  };

  xdg.mimeApps.defaultApplications = {
    "application/vnd.appimage" = [ "firejail-appimage.desktop" ];
  };
}
