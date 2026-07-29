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

        # RTKit: permite escalonamento em tempo real para o PipeWire
        security.rtkit.enable = true;

        # ── Overrides do Flatpak para o AudioRelay ─────────────────────────────
        #
        # CORREÇÃO 1 — Falha ao abrir (Java AWT/Swing em Wayland):
        #   O AudioRelay usa Java Swing/AWT. Em compositors Wayland sem GNOME,
        #   o AWT tenta detectar o gerenciador de janelas via reparenting e falha.
        #   _JAVA_AWT_WM_NONREPARENTING=1 desativa essa detecção.
        #   O Flatpak precisa de acesso ao socket Wayland e ao X11 (XWayland)
        #   como fallback para apps Java que não suportam Wayland nativo.
        #
        # CORREÇÃO 2 — Ícone quebrado/sem textura na bandeja do Noctalia:
        #   O Noctalia implementa StatusNotifierItem (SNI). Apps Flatpak precisam
        #   de permissão D-Bus para falar com org.kde.StatusNotifierWatcher.
        #   - XDG_CURRENT_DESKTOP=GNOME força o uso do protocolo SNI em vez do
        #     XEmbed legado (que não funciona em Wayland).
        #   - DBUS_SESSION_BUS_ADDRESS garante que o app encontre o D-Bus correto.
        #   - talk-name=org.kde.StatusNotifierWatcher é obrigatório para o ícone
        #     SNI ser visível em qualquer barra compatível.
        #   - filesystem=xdg-run/tray-icon:create permite escrever o arquivo de
        #     ícone temporário que o host lê para renderizar a imagem na bandeja.
        #
        services.flatpak.overrides.settings."net.audiorelay.AudioRelay" = {
          Context = {
            sockets = [ "wayland" "fallback-x11" ];
            filesystems = [ "xdg-run/tray-icon:create" ];
          };
          "Session Bus Policy" = {
            "org.kde.StatusNotifierWatcher" = "talk";
            "org.ayatana.indicator.application" = "talk";
            "com.canonical.AppMenu.Registrar" = "talk";
          };
          Environment = {
            XDG_CURRENT_DESKTOP = "GNOME";
            DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
            _JAVA_AWT_WM_NONREPARENTING = "1";
            AWT_TOOLKIT = "MToolkit";
          };
        };

        # ── Firewall ───────────────────────────────────────────────────────────
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
