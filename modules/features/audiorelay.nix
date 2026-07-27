{ ... }: {
  flake.nixosModules.audiorelay = { config, lib, pkgs, ... }:
    let
      cfg = config.services.audiorelay;
      audiorelayPort = 59100;
    in {
      options.services.audiorelay = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false; # Desabilitado por padrão para segurança
          description = "Habilita o AudioRelay.";
        };

        lanInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Interface de rede da LAN/Wi-Fi (ex: enp6s0).";
        };

        lanSubnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "CIDR da sub-rede local (ex: 192.168.1.0/24).";
        };
      };

      config = lib.mkIf cfg.enable {
        services.pipewire.extraConfig.pipewire."99-audiorelay" = {
          "context.objects" = [
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "audiorelay_sink";
                "node.description" = "AudioRelay (Saída para Celular)";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
              };
            }
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "audiorelay_source";
                "node.description" = "AudioRelay (Microfone do Celular)";
                "media.class" = "Audio/Source/Virtual";
                "audio.position" = "FL,FR";
              };
            }
          ];
        };
        services.pipewire = {
          enable = true;
          pulse.enable = true;
        };

        # Flatpak overrides só devem ser aplicados se flatpak estiver habilitado
        services.flatpak.overrides.settings = lib.mkIf config.services.flatpak.enable {
          "net.audiorelay.AudioRelay".Environment = {
            "_JAVA_AWT_WM_NONREPARENTING" = "1";
            "XDG_CURRENT_DESKTOP" = "GNOME";
          };
        };

        networking.nftables.enable = lib.mkIf (cfg.lanSubnet != null) true;

        networking.firewall = lib.mkMerge [
          (lib.mkIf (cfg.lanSubnet != null) {
            extraInputRules = ''
              ip saddr ${cfg.lanSubnet} tcp dport ${toString audiorelayPort} accept comment "AudioRelay (LAN apenas)"
              ip saddr ${cfg.lanSubnet} udp dport ${toString audiorelayPort} accept comment "AudioRelay (LAN apenas)"
            '';
          })
          (lib.mkIf (cfg.lanSubnet == null && cfg.lanInterface != null) {
            interfaces.${cfg.lanInterface} = {
              allowedTCPPorts = [ audiorelayPort ];
              allowedUDPPorts = [ audiorelayPort ];
            };
          })
        ];
      };
    };
}
