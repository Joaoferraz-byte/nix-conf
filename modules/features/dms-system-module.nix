{ config, lib, pkgs, ... }:
let
  cfg = config.services.dank-material-shell;
  dmsConfig = lib.attrByPath
    [ "home-manager" "users" cfg.userName "programs" "dank-material-shell" ]
    null
    config;
  enabledPlugins =
    if lib.isAttrs dmsConfig && lib.isAttrs (dmsConfig.plugins or null)
    then lib.filterAttrs
      (_: plugin:
        lib.isAttrs plugin
        && (plugin.enable or false)
        && (plugin.src or null) != null)
      dmsConfig.plugins
    else
      { };
  pluginFiles = lib.mapAttrs'
    (name: plugin: lib.nameValuePair "xdg/quickshell/dms-plugins/${name}" {
      source = plugin.src;
    })
    enabledPlugins;
in
{
  options.services.dank-material-shell.userName = lib.mkOption {
    type = lib.types.str;
    default = "livara";
    description = "Home Manager user that owns the DankMaterialShell session.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      quickshell
      matugen
      cava
      khal
      networkmanager
      glib
    ];

    environment.etc = pluginFiles;

    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.accounts-daemon.enable = lib.mkDefault true;
    services.geoclue2.enable = lib.mkDefault true;
    security.polkit.enable = lib.mkDefault true;
  };
}
