{
  flake.nixosModules.audiorelay = { config, lib, ... }:
    let
      cfg = config.services.audiorelay;
      audiorelayPort = 59100;
    in {
      options.services.audiorelay = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable AudioRelay with persistent PipeWire virtual nodes and firewall rules.";
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
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          extraConfig.pipewire-pulse."91-audiorelay" = {
            "pulse.cmd" = [
              {
                cmd = "load-module";
                args = "module-null-sink sink_name=audiorelay-virtual-mic-sink sink_properties=device.description=Virtual-Mic-Sink,media.class=Audio/Sink,node.description=Virtual-Mic-Sink,node.virtual=true";
              }
              {
                cmd = "load-module";
                args = "module-remap-source master=audiorelay-virtual-mic-sink.monitor source_name=audiorelay-virtual-mic source_properties=device.description=Virtual-Mic,media.class=Audio/Source,node.description=Virtual-Mic,node.virtual=true";
              }
              {
                cmd = "load-module";
                args = "module-null-sink sink_name=audiorelay-speakers sink_properties=device.description=AudioRelay-Speakers,media.class=Audio/Sink,node.description=AudioRelay-Speakers,node.virtual=true";
              }
            ];
          };
          wireplumber = {
            enable = true;
            extraConfig = {
              "11-bluetooth-policy" = {
                "wireplumber.settings" = {
                  "bluetooth.autoswitch-to-headset-profile" = true;
                };
              };
            } // lib.optionalAttrs config.hardware.bluetooth.enable {
              "12-bluetooth-autoconnect" = {
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
        };

        systemd.user.services.pipewire.serviceConfig.LimitNOFILE = 65536;
        systemd.user.services."pipewire-pulse".serviceConfig.LimitNOFILE = 65536;
        systemd.user.services.wireplumber.serviceConfig.LimitNOFILE = 65536;

        security.rtkit.enable = true;

        services.flatpak.overrides."net.audiorelay.AudioRelay" = {
          Context = {
            sockets = [ "pulseaudio" "x11" ];
            shares = [ "network" "ipc" ];
            devices = [ "dri" ];
            filesystems = [
              "/run/current-system/sw/share/X11/fonts:ro"
              "/nix/store:ro"
            ];
          };
          Environment = {
            SKIKO_RENDER_API = "SOFTWARE";
            _JAVA_AWT_WM_NONREPARENTING = "1";
          };
        };

        fonts.fontDir.enable = true;
        networking.firewall.allowedUDPPorts = [ audiorelayPort ];
      };
    };
}
