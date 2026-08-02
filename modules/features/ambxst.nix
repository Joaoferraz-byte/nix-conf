{ self, inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, config, lib, ... }: {
    # 1. Injeta o módulo NixOS do shell-conf no sistema
    imports = [ inputs.shell-conf.nixosModules.default ];

    # 2. Ativa o programa ambxst no nível do sistema
    programs.ambxst = {
      enable = true;
      package = inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # UWSM alcança graphical-session.target somente depois de importar o
    # ambiente Wayland/DBus. Associar o shell a esse alvo evita que o Lua do
    # Hyprland e um serviço systemd concorram para iniciar Quickshell.
    systemd.user.services.ambxst = {
      description = "Ambxst Quickshell session";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = [ "-${pkgs.coreutils}/bin/mkdir -p %h/.local/state/ambxst/config" ];
        ExecStart = "${config.programs.ambxst.package}/bin/ambxst";
        Restart = "on-failure";
        RestartSec = 2;
        Slice = "session.slice";
      };
      # Ensure XDG_STATE_HOME is consistent regardless of session inheritance.
      # Ambxst resolves its config root from AMBXST_CONFIG_ROOT (set by the
      # launcher wrapper) which falls back to XDG_STATE_HOME/ambxst.
      environment = {
        XDG_STATE_HOME = "/home/${config.users.users.livara.name}/.local/state";
      };
      # Explicitly add system PATH so the shell can find system-level tools
      # like nmcli, bluetoothctl, hyprctl, systemctl, and loginctl that are
      # not part of the shell's own Nix closure.
      path = [ "/run/current-system/sw" ];
    };

    # ── Sincronização Automática: UI → shell-conf repo ─────────────────
    # Este serviço executa o script sync-ambxst-presets.sh periodicamente
    # via timer systemd (a cada 5 minutos). Ele copia os arquivos JSON
    # editados via UI de volta para o repositório shell-conf, garantindo
    # que as preferências do usuário sobrevivam a rebuilds do NixOS.
    #
    # O commit para o Git NÃO é automático — o usuário decide quando
    # commitar e pushar as alterações.
    systemd.user.services.sync-ambxst-presets = {
      description = "Sync Ambxst user config to shell-conf preset directory";
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          syncScript = pkgs.writeShellApplication {
            name = "sync-ambxst-presets";
            runtimeInputs = [ pkgs.coreutils pkgs.bash ];
            text = ''
              set -euo pipefail

              CONFIG_ROOT="''${AMBXST_CONFIG_ROOT:-''${XDG_STATE_HOME:-$HOME/.local/state}/ambxst}"
              CONFIG_DIR="''${CONFIG_ROOT}/config"
              SHELL_CONF_DIR="/home/livara/Projects/shell-conf"
              PRESET_DIR="''${SHELL_CONF_DIR}/assets/presets/Ambxst Default"

              # Validação silenciosa
              [[ -d "$CONFIG_DIR" ]] || exit 0
              [[ -d "$PRESET_DIR" ]] || exit 0

              EXCLUDED=("system.json" "ai.json" "prefix.json" "weather.json" "general.json")

              for json_file in "$CONFIG_DIR"/*.json; do
                [[ -f "$json_file" ]] || continue
                filename="$(basename "$json_file")"

                # Pular arquivos excluídos
                skip=false
                for excluded in "''${EXCLUDED[@]}"; do
                  [[ "$filename" == "$excluded" ]] && skip=true && break
                done
                $skip && continue

                dest="''${PRESET_DIR}/''${filename}"
                src="''${CONFIG_DIR}/''${filename}"

                # Só copiar se o conteúdo mudou
                if [[ -f "$dest" ]] && diff -q "$src" "$dest" > /dev/null 2>&1; then
                  continue
                fi

                cp "$src" "$dest"
              done
            '';
          };
        in [ "${syncScript}/bin/sync-ambxst-presets" ];
        Restart = "no";
      };
    };

    # Timer que dispara o serviço a cada 5 minutos, com delay de 1 minuto
    # após o boot para permitir que a sessão gráfica inicie completamente.
    systemd.user.timers.sync-ambxst-presets = {
      description = "Timer for syncing Ambxst presets";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Unit = "sync-ambxst-presets.service";
      };
    };

    # 3. Garante que o módulo de Home Manager do shell-conf seja injetado 
    # em todos os usuários que usam home-manager.
    # Isso resolve o problema de o estado mutável (~/.local/state/ambxst)
    # não ser inicializado, o que impedia o AMBXST de subir.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];

    environment.systemPackages = with pkgs; [
      kitty
      tmux
      fuzzel
      networkmanagerapplet
      blueman
      pavucontrol
      easyeffects
      hicolor-icon-theme
    ];

    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.blueman.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.gnome.gnome-keyring.enable = lib.mkDefault true;
  };
}
