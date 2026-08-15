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
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber = {
            enable = true;
            extraConfig."10-bluez-profiles" = {
              "monitor.bluez.properties" = {
                "bluez5.auto-connect" = [ "a2dp_sink" "hfp_hf" ];
              };
            };
            extraConfig."11-bluetooth-policy" = {
              "wireplumber.settings" = {
                "bluetooth.autoswitch-to-headset-profile" = false;
              };
            };
          };
        };

        security.rtkit.enable = true;

        services.flatpak.overrides."net.audiorelay.AudioRelay" = {
          Context = {
            sockets = [ "x11" ];
          };
          Environment = {
            _JAVA_AWT_WM_NONREPARENTING = "1";
          };
        };

        networking.firewall.allowedUDPPorts = [ audiorelayPort ];
      };
    };
}
