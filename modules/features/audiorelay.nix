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

        systemd.user.services.audiorelay-virtual-audio = {
          enable = true;
          description = "Create AudioRelay virtual sink, monitor microphone and speaker sink";
          after = [ "pipewire-pulse.service" "wireplumber.service" ];
          wants = [ "pipewire-pulse.service" "wireplumber.service" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = pkgs.writeShellScript "audiorelay-virtual-audio" ''
              # AudioRelay's Linux integration consumes PulseAudio-compatible
              # devices. PipeWire-pulse exposes these pactl modules reliably.
              set -u
              pactl="${pkgs.pulseaudio}/bin/pactl"
              wait_for_pulse() {
                for _ in $(seq 1 30); do
                  "$pactl" info >/dev/null 2>&1 && return 0
                  sleep 1
                done
                return 1
              }
              module_id() {
                "$pactl" list short modules | awk -v needle="$1" '$0 ~ needle {print $1; exit}'
              }
              ensure_module() {
                local needle="$1"
                shift
                if [[ -z "$(module_id "$needle")" ]]; then
                  "$pactl" load-module "$@" >/dev/null 2>&1 || true
                fi
              }
              while wait_for_pulse; do
                ensure_module 'sink_name=audiorelay-virtual-mic-sink' \
                  module-null-sink sink_name=audiorelay-virtual-mic-sink \
                  sink_properties=device.description=Virtual-Mic-Sink
                ensure_module 'source_name=audiorelay-virtual-mic' \
                  module-remap-source master=audiorelay-virtual-mic-sink.monitor \
                  source_name=audiorelay-virtual-mic \
                  source_properties=device.description=Virtual-Mic
                ensure_module 'sink_name=audiorelay-speakers' \
                  module-null-sink sink_name=audiorelay-speakers \
                  sink_properties=device.description=AudioRelay-Speakers
                sleep 5
              done
              exit 75
            '';
            Restart = "always";
            RestartSec = 3;
          };
          wantedBy = [ "default.target" ];
        };

        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber = {
            enable = true;
            extraConfig."11-bluetooth-policy" = {
              "wireplumber.settings" = {
                # Keep high-fidelity A2DP until an application actually needs
                # the headset microphone; this is the documented WirePlumber
                # policy setting, not an Easy Effects workaround.
                "bluetooth.autoswitch-to-headset-profile" = true;
              };
            };
            extraConfig."12-bluetooth-autoconnect" = {
              "monitor.bluez.rules" = [
                {
                  matches = [
                    { "device.name" = "~bluez_card.*"; }
                  ];
                  actions = {
                    "update-props" = {
                      "bluez5.auto-connect" = [ "a2dp_sink" "hfp_hf" "hsp_hs" ];
                    };
                  };
                }
              ];
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
