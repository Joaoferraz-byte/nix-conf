{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
    environment.systemPackages = with pkgs; [
      grim
      slurp
      wl-clipboard
      brightnessctl
      bibata-cursors
      xwayland-satellite
    ];
  };

  perSystem =
    {
      pkgs,
      lib,
      self',
      system,
      ...
    }:
    {
      packages.myNiri =
        let
          # ── PREDICTIVE-001: nixpkgs-stable pin para o Niri ──────────────────
          # TODO: Remover este pin quando o problema de libdisplay-info for
          # resolvido no nixos-unstable. Verificar periodicamente se:
          #   nix build nixpkgs#niri  (sem o pin) funciona sem erros de libdisplay-info.
          # O pin atual é nixos-25.05 (rev 77981d0d8e43).
          # Correção nixpkgs-stable (libdisplay-info)
          stablePkgs = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        inputs.wrapper-modules.wrappers.niri.wrap {
          package = stablePkgs.niri;
          inherit pkgs;
          settings = {
            # ── Startup ─────────────────────────────────────────────────
            # O Ambxst substitui o Noctalia como shell principal.
            # O wrapper "ambxst" inicializa o axctl (daemon IPC para Niri)
            # e o Quickshell com o shell.qml do Ambxst.
            spawn-at-startup = [
              [ "ambxst" ]
            ];

            xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

            input = {
              keyboard.xkb.layout = "br";
              touchpad = {
                tap = _: { };
                natural-scroll = _: { };
              };
            };

            layout = {
              gaps = 14;
              center-focused-column = "never";
              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];
              border = {
                width = 0.5;
                active-color = "rgba(255, 255, 255, 0.5)";
                inactive-color = "rgba(128, 128, 128, 0.3)";
              };
              default-column-width = {
                proportion = 0.5;
              };
              focus-ring = {
                width = 1;
                active-color = "#7fc8ff";
                inactive-color = "#505050";
              };
            };

            cursor = {
              xcursor-theme = "Bibata-Modern-Classic";
              xcursor-size = 24;
              hide-when-typing = _: { };
              hide-after-inactive-ms = 3000;
            };

            window-rules = [
              # ── Regra geral para todas as janelas ──────────────────────
              {
                matches = [ { app-id = ".*"; } ];
                geometry-corner-radius = 12;
                clip-to-geometry = true;
                opacity = 0.80;
                background-effect = {
                  blur = true;
                };
                draw-border-with-background = true;
              }
              # ── Regra específica para o Quickshell/Ambxst ──────────────
              # A barra do Ambxst não deve ter bordas, sombras ou arredondamento
              # do compositor — ela gerencia sua própria aparência via QML.
              {
                matches = [ { app-id = "^quickshell$"; } ];
                draw-border-with-background = false;
                opacity = 1.0;
                geometry-corner-radius = 0;
                clip-to-geometry = false;
              }
            ];

            prefer-no-csd = true;
            hotkey-overlay.skip-at-startup = true;

            binds = {
              # ── Aplicativos ──────────────────────────────────────────────
              "Mod+Return".spawn-sh = lib.getExe pkgs.alacritty;
              "Mod+O".spawn-sh = lib.getExe pkgs.obsidian;
              "Mod+W".spawn-sh = lib.getExe pkgs.brave;
              "Mod+E".spawn-sh = lib.getExe pkgs.nautilus;

              # ── Integração com IPC do Ambxst ─────────────────────────────
              # O Niri envia comandos para o Ambxst via pipe FIFO.
              # O GlobalShortcuts.qml do Ambxst escuta este pipe e executa
              # as ações correspondentes na UI do shell.
              #
              # Referência: Ambxst/modules/services/GlobalShortcuts.qml
              "Mod+S".spawn-sh = "echo launcher > /tmp/ambxst_ipc.pipe";
              "Mod+D".spawn-sh = "echo dashboard > /tmp/ambxst_ipc.pipe";
              "Mod+A".spawn-sh = "echo assistant > /tmp/ambxst_ipc.pipe";
              "Mod+V".spawn-sh = "echo clipboard > /tmp/ambxst_ipc.pipe";
              "Mod+Period".spawn-sh = "echo emoji > /tmp/ambxst_ipc.pipe";
              "Mod+N".spawn-sh = "echo notes > /tmp/ambxst_ipc.pipe";
              "Mod+Comma".spawn-sh = "echo wallpapers > /tmp/ambxst_ipc.pipe";
              "Mod+Tab".spawn-sh = "echo overview > /tmp/ambxst_ipc.pipe";
              "Mod+Escape".spawn-sh = "echo powermenu > /tmp/ambxst_ipc.pipe";
              "Mod+L".spawn-sh = "echo lockscreen > /tmp/ambxst_ipc.pipe";
              "Mod+Shift+S".spawn-sh = "echo screenshot > /tmp/ambxst_ipc.pipe";

              # ── Gerenciamento de janelas (Niri nativo) ───────────────────
              "Mod+Q".close-window = _: { };
              "Mod+F".maximize-column = _: { };
              "Mod+Shift+F".fullscreen-window = _: { };
              # Toggle floating: movido para SUPER+Shift+V (SUPER+V agora é clipboard)
              "Mod+Shift+V".toggle-window-floating = _: { };
              # Consume/expel: movidos para SUPER+Ctrl (SUPER+, e SUPER+. agora são do Ambxst)
              "Mod+Ctrl+Comma".consume-window-into-column = _: { };
              "Mod+Ctrl+Period".expel-window-from-column = _: { };

              # ── Foco e movimento ─────────────────────────────────────────
              "Mod+Left".focus-column-left = _: { };
              "Mod+Right".focus-column-right = _: { };
              "Mod+Up".focus-window-up = _: { };
              "Mod+Down".focus-window-down = _: { };
              "Mod+Shift+Left".move-column-left = _: { };
              "Mod+Shift+Right".move-column-right = _: { };
              "Mod+Shift+Up".move-window-up = _: { };
              "Mod+Shift+Down".move-window-down = _: { };

              # ── Redimensionamento ────────────────────────────────────────
              "Mod+R".switch-preset-column-width = _: { };
              "Mod+Minus".set-column-width = "-10%";
              "Mod+Equal".set-column-width = "+10%";

              # ── Workspaces ───────────────────────────────────────────────
              "Mod+1".focus-workspace = 1;
              "Mod+2".focus-workspace = 2;
              "Mod+3".focus-workspace = 3;
              "Mod+4".focus-workspace = 4;
              "Mod+Shift+1".move-column-to-workspace = 1;
              "Mod+Shift+2".move-column-to-workspace = 2;
              "Mod+Shift+3".move-column-to-workspace = 3;
              "Mod+Shift+4".move-column-to-workspace = 4;
              "Mod+Page_Down".focus-workspace-down = _: { };
              "Mod+Page_Up".focus-workspace-up = _: { };

              # ── Screenshot nativo do Niri ────────────────────────────────
              "Print".screenshot = _: { };
              "Mod+Print".screenshot-window = _: { };

              # ── Áudio e brilho ───────────────────────────────────────────
              "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
              "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
              "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              "XF86MonBrightnessUp".spawn-sh = "brightnessctl set +5%";
              "XF86MonBrightnessDown".spawn-sh = "brightnessctl set 5%-";

              # ── Sair do Niri ─────────────────────────────────────────────
              "Mod+Shift+E".quit = _: { };
            };
          };
        };
    };
}
