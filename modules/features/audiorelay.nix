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
          description = "Habilita o AudioRelay.";
        };

        lanInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "enp6s0";
          description = "Interface de rede da LAN/Wi-Fi.";
        };

        lanSubnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "10.253.8.96/24";
          description = "CIDR da sub-rede local.";
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

        services.flatpak.overrides.settings = {
          "net.audiorelay.AudioRelay".Environment = {
            "_JAVA_AWT_WM_NONREPARENTING" = "1";
            "XDG_CURRENT_DESKTOP" = "GNOME"; # Força o uso do StatusNotifierItem (appindicator) que funciona melhor no Noctalia/GNOME
            "DBUS_SESSION_BUS_ADDRESS" = "unix:path=/run/user/1000/bus"; # Garante comunicação D-Bus correta para o tray
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
