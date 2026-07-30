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
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      # ── Roteamento por interface (BUG-007) ─────────────────────────────
      # Usar config.common.default = "gnome" roteava TODAS as requisições
      # para o portal GNOME, causando falhas de inicialização em sessões
      # não-GNOME (Niri). O roteamento por interface é mais robusto:
      # - ScreenCast/Screenshot → gnome (suporte nativo a Wayland PipeWire)
      # - Tudo mais → gtk (fallback universal, funciona sem GNOME)
      # Referência: nixpkgs#391489, portals.conf(5)
      config = {
        common = {
          default = [ "gtk" ];
          "org.freedesktop.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.portal.RemoteDesktop" = [ "gnome" ];
        };
      };
    };
  };
}
