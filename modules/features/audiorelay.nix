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
          # Noctalia enumerates PipeWire Audio/Sink and Audio/Source nodes. Keep
          # these classes explicit because they are created through pipewire-pulse.
          ensure_module 'sink_name=audiorelay-virtual-mic-sink' \
            module-null-sink sink_name=audiorelay-virtual-mic-sink \
            sink_properties=device.description=Virtual-Mic-Sink,media.class=Audio/Sink,node.description=Virtual-Mic-Sink,node.virtual=true
          # AudioRelay's remap source uses the monitor sink name as
          # source_name; the description is the user-facing Virtual-Mic device.
          ensure_module 'source_name=audiorelay-virtual-mic-sink' \
            module-remap-source master=audiorelay-virtual-mic-sink.monitor \
            source_name=audiorelay-virtual-mic-sink \
            source_properties=device.description=Virtual-Mic,media.class=Audio/Source,node.description=Virtual-Mic,node.virtual=true
          ensure_module 'sink_name=audiorelay-speakers' \
            module-null-sink sink_name=audiorelay-speakers \
            sink_properties=device.description=AudioRelay-Speakers,media.class=Audio/Sink,node.description=AudioRelay-Speakers,node.virtual=true
        '';
      };
    in {
      options.services.audiorelay = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable AudioRelay with PipeWire virtual nodes and firewall rules.";
        };
        lanInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "enp6s0";
          description = "LAN/Wi-Fi network interface for AudioRelay traffic.";
        };
        lanSubnet = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "10.253.8.96/24";
          description = "Local subnet CIDR for AudioRelay firewall rules.";
        };
      };

      config = lib.mkIf cfg.enable {
        # The pactl modules only need to be created once; no permanent
        # subscribe loop. The unit restarts with pipewire-pulse.
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
                # Keep high-fidelity A2DP until an app needs the headset mic.
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

        # Guardrail for PipeWire EMFILE (fd exhaustion) on the host.
        systemd.user.services.pipewire.serviceConfig.LimitNOFILE = 65536;
        systemd.user.services."pipewire-pulse".serviceConfig.LimitNOFILE = 65536;
        systemd.user.services.wireplumber.serviceConfig.LimitNOFILE = 65536;

        security.rtkit.enable = true;

        services.flatpak.overrides."net.audiorelay.AudioRelay" = {
          Context = {
            # AudioRelay uses JetBrains Skiko (Skia+OpenGL) for rendering, which
            # has no Wayland backend — it always uses the X11/GLX path. Use
            # unconditional "x11" (not "fallback-x11") so the sandbox gets X11
            # access under a Wayland session via XWayland (niri 25.08+ provides
            # xwayland-satellite out of the box).
            sockets = [ "pulseaudio" "x11" ];

            # --share=ipc is required for the X11/GLX path (MIT-SHM, DRI3/GLX).
            shares = [ "network" "ipc" ];

            # Explicit device=dri works around flatpak #6672 on NVIDIA
            # proprietary where --device=all doesn't expose /dev/dri/renderD128.
            devices = [ "dri" ];

            # Skiko lazily loads fonts on first render; without access to the
            # NixOS font tree it crashes with "Could not load font". See
            # fonts.fontDir.enable below.
            filesystems = [
              "/run/current-system/sw/share/X11/fonts:ro"
              "/nix/store:ro"
            ];
          };
          Environment = {
            # Forces Skiko to use software rasterizer instead of OpenGL,
            # avoiding blank/white window on NVIDIA+XWayland (AudioRelay
            # community threads 988, 1024, 1506).
            SKIKO_RENDER_API = "SOFTWARE";
            # Non-reparenting WM hint for Java/AWT apps under tiling WMs.
            _JAVA_AWT_WM_NONREPARENTING = "1";
          };
        };

        # Creates /run/current-system/sw/share/X11/fonts for the flatpak
        # font filesystem override above.
        fonts.fontDir.enable = true;

        networking.firewall.allowedUDPPorts = [ audiorelayPort ];
      };
    };
}
