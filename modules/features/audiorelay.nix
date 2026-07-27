{ ... }: {
  flake.nixosModules.audiorelay = { config, lib, pkgs, ... }:
    let
      cfg = config.services.audiorelay;
    in {
      options.services.audiorelay = {
        enable = lib.mkEnableOption "AudioRelay (Pipewire Virtual Sinks)";
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
          };
        };
      };
    };
}

