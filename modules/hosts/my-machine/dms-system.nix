# ─── DMS system-level dependencies ─────────────────────────────────────────
# DMS's upstream NixOS module declares `programs.dank-material-shell.systemd`
# options in BOTH its NixOS module and its Home Manager module, which makes
# them impossible to enable together on the same machine ("already declared"
# option conflict). We therefore do NOT import the upstream NixOS module and
# instead re-declare the system-level pieces it used to provide here. The
# user-level pieces (settings, session, systemd service, Quickshell) are
# supplied by the shell-conf Home Manager module.
{ self, inputs, ... }: {
  flake.nixosModules.dmsSystem = { config, pkgs, lib, ... }: {
    # DMS runtime dependencies that were previously installed by the upstream
    # NixOS module (distro/nix/common.nix `packages` + NixOS body).
    environment.systemPackages =
      let
        dmsCfg = config.home-manager.users.livara.programs.dank-material-shell or null;
      in
      [ pkgs.quickshell pkgs.matugen pkgs.cava pkgs.khal pkgs.networkmanager pkgs.glib ];

    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.accounts-daemon.enable = lib.mkDefault true;
    services.geoclue2.enable = lib.mkDefault true;
    security.polkit.enable = lib.mkDefault true;

    # Quickshell plugin sources expected at /etc/xdg/quickshell/dms-plugins/*
    environment.etc =
      let
        dmsCfg = config.home-manager.users.livara.programs.dank-material-shell or null;
        plugins =
          if dmsCfg != null && lib.isAttrs (dmsCfg.plugins or null)
          then
            lib.mapAttrs'
              (name: plugin: lib.nameValuePair ("xdg/quickshell/dms-plugins/${name}") plugin.src)
              (lib.filterAttrs (_: p: p.enable or false && (p.src or null) != null) dmsCfg.plugins)
          else
            { };
      in
      plugins;
  };
}
