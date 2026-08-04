{ ... }: {
  flake.nixosModules.audiorelay = { config, lib, pkgs, ... }:
    let
      cfg = config.services.audiorelay;
      audiorelayPort = 59100;
    in {
      options.services.audiorelay = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Ativar AudioRelay com nós virtuais PipeWire e regras de firewall.";
        };
        lanInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "enp6s0";
          description = "Interface de rede LAN/Wi-Fi para permitir tráfego AudioRelay.";
        };
        lanSubnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "10.253.8.96/24";
          description = "CIDR da sub-rede local para regras de firewall do AudioRelay.";
        };
      };

      config = lib.mkIf cfg.enable {

        # ── Nós virtuais PipeWire ──────────────────────────────────────────────
        services.pipewire.extraConfig.pipewire."99-audiorelay" = {
          "context.objects" = [
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "audiorelay_sink";
                "node.description" = "AudioRelay (saída para o telefone)";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
              };
            }
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "audiorelay_source";
                "node.description" = "AudioRelay (microfone do telefone)";
                "media.class" = "Audio/Source";
                "audio.position" = "FL,FR";
              };
            }
          ];
        };

        services.pipewire = {
          enable = true;
          pulse.enable = true;
          # Fornece o session manager e `wpctl`, usado pelos binds multimídia
          # do Hyprland para volume e mute.
          wireplumber.enable = true;
        };

        # RTKit: permite escalonamento em tempo real para o PipeWire
        security.rtkit.enable = true;

        # ── Overrides do Flatpak para o AudioRelay ─────────────────────────────
        #
        # O AudioRelay usa Java Swing/AWT. Em compositors Wayland sem GNOME,
        # o AWT tenta detectar o gerenciador de janelas via reparenting e falha.
        # _JAVA_AWT_WM_NONREPARENTING=1 desativa essa detecção.
        # O Flatpak precisa de acesso ao socket X11 (XWayland) como fallback
        # para apps Java que não suportam Wayland nativo.
        #
        services.flatpak.overrides.settings."net.audiorelay.AudioRelay" = {
          Context = {
            sockets = [ "x11" ];
          };
          Environment = {
            _JAVA_AWT_WM_NONREPARENTING = "1";
          };
        };

        # ── Firewall ───────────────────────────────────────────────────────────
        # Ports are opened in system-hardening.nix
        networking.firewall.allowedUDPPorts = [ audiorelayPort ];
      };
    };
}
