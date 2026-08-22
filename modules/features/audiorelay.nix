{
  flake.nixosModules.audiorelay = { config, lib, pkgs, ... }:
    let
      cfg = config.services.audiorelay;
      audiorelayPort = 59100;
      audiorelayVirtualAudio = pkgs.writeShellApplication {
        name = "audiorelay-virtual-audio";
        runtimeInputs = with pkgs; [ coreutils gawk pulseaudio ];
        text = ''
          # AudioRelay's Linux integration consumes PulseAudio-compatible
          # devices. PipeWire-pulse exposes these pactl modules reliably.
          set -Eeuo pipefail
          pactl="${pkgs.pulseaudio}/bin/pactl"
          timeout_bin="${pkgs.coreutils}/bin/timeout"

          wait_for_pulse() {
            for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
              if "$timeout_bin" 2s "$pactl" info >/dev/null 2>&1; then
                return 0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
            return 1
          }

          module_id() {
            "$timeout_bin" 5s "$pactl" list short modules \
              | ${pkgs.gawk}/bin/awk -v needle="$1" '$0 ~ needle {print $1; exit}'
          }

          remove_legacy_mic_source() {
            "$timeout_bin" 5s "$pactl" list short modules \
              | ${pkgs.gawk}/bin/awk '$0 ~ /source_name=audiorelay-virtual-mic([[:space:]]|$)/ {print $1}' \
              | while read -r id; do
                  [[ -n "$id" ]] && "$timeout_bin" 5s "$pactl" unload-module "$id" >/dev/null 2>&1 || true
                done
          }

          ensure_module() {
            local needle="$1"
            shift
            if [[ -z "$(module_id "$needle")" ]]; then
              "$timeout_bin" 5s "$pactl" load-module "$@" >/dev/null
            fi
          }

          wait_for_pulse
          remove_legacy_mic_source
          ensure_module 'sink_name=audiorelay-virtual-mic-sink' \
            module-null-sink sink_name=audiorelay-virtual-mic-sink \
            sink_properties=device.description=Virtual-Mic-Sink
          # AudioRelay's documented remap source uses the monitor sink
          # name as source_name; the description is the user-facing
          # Virtual-Mic device selected by communication applications.
          ensure_module 'source_name=audiorelay-virtual-mic-sink' \
            module-remap-source master=audiorelay-virtual-mic-sink.monitor \
            source_name=audiorelay-virtual-mic-sink \
            source_properties=device.description=Virtual-Mic
          ensure_module 'sink_name=audiorelay-speakers' \
            module-null-sink sink_name=audiorelay-speakers \
            sink_properties=device.description=AudioRelay-Speakers
        '';
      };
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
        # AudioRelay only needs one PulseAudio-compatibility connection while
        # the modules are created. Keeping a permanent pactl subscribe loop
        # here unnecessarily consumes a server connection and can amplify a
        # PipeWire fd leak. The unit is restarted when pipewire-pulse restarts.
        systemd.user.services.audiorelay-virtual-audio = {
          enable = true;
          description = "Create AudioRelay virtual sink, monitor microphone and speaker sink";
          after = [ "pipewire-pulse.service" "wireplumber.service" ];
          wants = [ "pipewire-pulse.service" "wireplumber.service" ];
          bindsTo = [ "pipewire-pulse.service" ];
          partOf = [ "pipewire-pulse.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${audiorelayVirtualAudio}/bin/audiorelay-virtual-audio";
            Restart = "on-failure";
            RestartSec = 5;
            LimitNOFILE = 65536;
          };
          wantedBy = [ "pipewire-pulse.service" ];
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

        # PipeWire's native server was rejecting new clients with EMFILE on
        # the host. Raising the user-service ceiling is a guardrail, not a
        # substitute for closing duplicate clients; the AudioRelay unit above
        # removes its permanent subscription so the graph remains bounded.
        systemd.user.services.pipewire.serviceConfig.LimitNOFILE = 65536;
        systemd.user.services."pipewire-pulse".serviceConfig.LimitNOFILE = 65536;
        systemd.user.services.wireplumber.serviceConfig.LimitNOFILE = 65536;

        security.rtkit.enable = true;

        services.flatpak.overrides."net.audiorelay.AudioRelay" = {
          Context = {
            # AudioRelay's Linux client uses the PulseAudio compatibility API;
            # with PipeWire this is provided by pipewire-pulse. The previous
            # x11-only override removed the audio socket from the sandbox.
            sockets = [ "pulseaudio" "wayland" "fallback-x11" ];
            shares = [ "network" ];
          };
          Environment = {
            _JAVA_AWT_WM_NONREPARENTING = "1";
          };
        };

        networking.firewall.allowedUDPPorts = [ audiorelayPort ];
      };
    };
}
