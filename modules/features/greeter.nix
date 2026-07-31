# ─── SDDM Display Manager + Pixie Theme ───────────────────────────────────
# SDDM is the recommended display manager for Hyprland/Wayland.
# We use the pixie-sddm theme (inspired by Google Pixel UI / Material Design 3)
# from the flake input github:xCaptaiN09/pixie-sddm.
#
# Visual Sync with Ambxst-X:
#   - autoColor = true  →  extrai cores Material You do wallpaper (mesma paleta do shell)
#   - background       →  wallpaper do Ambxst (Wallpapers/ dir)
#   - avatar           →  ícone do Ambxst (Icons/ dir)
#   - accentColor      →  fallback caso autoColor não consiga extrair
#
# NOTA: Usamos self.outPath + "/Icons/" porque o greeter.nix vive em
# modules/features/ e paths relativos (./Icons/) resolveriam para
# modules/features/Icons/ que não existe.
#
# PADDING: O theme.conf do pixie-sddm NÃO expõe padding como opção.
# Para aumentar o espaçamento do input de senha, sobrescrevemos a deri-
# vação upstream e aplicamos sed em Main.qml no postPatch.
#   - ColumnLayout anchors.margins: 40 → 55
#   - passwordField Layout.topMargin: 30 → 45
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, config, ... }: let
    # Derivação que copia wallpapers e ícones para o Nix store.
    # self.outPath aponta para a raiz do repositório nix-conf.
    assets = pkgs.runCommand "ambxst-sddm-assets" {} ''
      mkdir -p $out/background $out/avatar
      cp ${self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg"} $out/avatar/avatar.jpg
      cp ${self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg"} $out/background/background.jpg
    '';

    # Upstream pixie-sddm theme (build from flake input)
    upstreamTheme = inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Wrapper que herda do upstream e patcheia Main.qml para aumentar padding
    pixieTheme = pkgs.stdenvNoCC.mkDerivation {
      pname = "pixie-sddm-custom";
      version = "3.0-patched";

      # Usa o upstream como source — copia o conteúdo instalado
      src = pkgs.runCommand "pixie-source" {} ''
        mkdir -p $out
        # Copia o tema upstream instalado
        cp -r ${upstreamTheme}/share/sddm/themes/pixie/* $out/
      '';

      # Aplica customizações após copiar o source
      postPatch = ''
        # ── Configurações de cores (theme.conf) ────────────────────────
        update_ini() {
          local key="$1"
          local value="$2"
          [ -z "$value" ] && return
          if grep -q "^$key=" theme.conf; then
            sed -i "s|^$key=.*|$key=$value|" theme.conf
          else
            echo "$key=$value" >> theme.conf
          fi
        }

        update_ini "accentColor" "#ffb3ae"
        update_ini "autoColor" "true"
        update_ini "backgroundColor" "#1a1111"
        update_ini "textColor" "#E3E3DC"

        # ── Padding do login: aumenta espaçamento interno ──────────────
        # ColumnLayout anchors.margins: 40 → 55 (mais respiro interno)
        # passwordField Layout.topMargin: 30 → 45 (mais espaço acima)
        sed -i 's/anchors\.margins: 40/anchors.margins: 55/' Main.qml
        sed -i 's/Layout\.topMargin: 30 \/\//Layout.topMargin: 45 \/\//' Main.qml

        # ── Assets personalizados ───────────────────────────────────────
        mkdir -p assets
        cp ${assets + "/background/background.jpg"} assets/background.jpg
        cp ${assets + "/avatar/avatar.jpg"} assets/avatar.jpg
      '';

      installPhase = ''
        mkdir -p $out/share/sddm/themes/pixie
        cp -r * $out/share/sddm/themes/pixie/
      '';
    };
  in {
    environment.systemPackages = [ pixieTheme ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Required for Hyprland
      theme = "pixie";
      extraPackages = with pkgs; [
        pixieTheme
        kdePackages.qtmultimedia # Required for video backgrounds/audio
        kdePackages.qtsvg
        kdePackages.qtdeclarative
        kdePackages.qtwayland
      ];
    };

    # ── Fonts: provide Cantarell + Noto for the greeter ─────────────────
    fonts.packages = with pkgs; [
      cantarell-fonts
      noto-fonts
      noto-fonts-color-emoji
    ];
  };
}
