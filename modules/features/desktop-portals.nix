{ ... }: {
  flake.nixosModules.desktop-portals = { pkgs, ... }: {
    security.polkit.enable = true;
    # Agente de autenticação Polkit (prompt GUI para ações root/sudo)
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    xdg.portal = {
      enable = true;
      # O módulo programs.hyprland já adiciona xdg-desktop-portal-hyprland.
      # GTK complementa apenas o file chooser, não implementado pelo XDPH.
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      # O backend Hyprland deve tratar ScreenCast, Screenshot, RemoteDesktop e
      # atalhos globais. GTK permanece como fallback para capacidades que ele
      # não fornece, especialmente FileChooser.
      config = {
        common.default = [ "hyprland" "gtk" ];
        hyprland.default = [ "hyprland" "gtk" ];
      };
    };
  };
}
