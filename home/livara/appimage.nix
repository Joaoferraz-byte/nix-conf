{ pkgs, ... }:
{
  xdg.desktopEntries.firejail-appimage = {
    name = "Firejail AppImage";
    comment = "Run an AppImage in a disposable sandbox";
    exec = "${pkgs.firejail}/bin/firejail --appimage --private --net=none --caps.drop=all --seccomp -- %f";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    mimeType = [ "application/vnd.appimage" ];
  };

  xdg.mimeApps.defaultApplications = {
    "application/vnd.appimage" = [ "firejail-appimage.desktop" ];
  };
}
