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
          description = "Ativar AudioRelay.";
        };
        lanInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "enp6s0";
          description = "Interface de rede LAN/Wi-Fi.";
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
                "node.description" = "AudioRelay (phone output)";
                "media.class" = "Audio/Sink";
                "audio.position" = "FL,FR";
              };
            }
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "audiorelay_source";
                "node.description" = "AudioRelay (phone microphone)";
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

        # Permite escalonamento em tempo real para o PipeWire
        security.rtkit.enable = true;

        # Compatibilidade com ícone de bandeja e Java/Wayland para Flatpak
        services.flatpak.overrides.settings = {
          "net.audiorelay.AudioRelay" = {
            Context.sockets = [ "wayland" "fallback-x11" ];
            Context.filesystems = [ "xdg-config/gtk-3.0:ro" "xdg-run/flatpak-info:ro" ];
            Environment = {
              "_JAVA_AWT_WM_NONREPARENTING" = "1";
              "GDK_BACKEND" = "wayland,x11";
              # Protocolo StatusNotifierItem para a bandeja Noctalia
              "XDG_CURRENT_DESKTOP" = "GNOME";
              "DBUS_SESSION_BUS_ADDRESS" = "unix:path=\$XDG_RUNTIME_DIR/bus";
            };
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
