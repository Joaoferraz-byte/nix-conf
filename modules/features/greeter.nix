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
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, config, ... }: let
    # Derivação que copia wallpapers e ícones para o Nix store.
    # self.outPath aponta para a raiz do repositório nix-conf.
    assets = pkgs.runCommand "ambxst-sddm-assets" {} ''
      mkdir -p $out/background $out/avatar
      cp ${self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg"} $out/avatar/avatar.jpg
      cp ${self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg"} $out/background/background.jpg
    '';
    pixieTheme = inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      background = assets + "/background/background.jpg";
      avatar = assets + "/avatar/avatar.jpg";
      autoColor = true;   # Extrai paleta Material You do wallpaper → sincroniza com Ambxst
      accentColor = "#ffb3ae"; # Fallback warm-pink (cor primária default do Ambxst)
      backgroundColor = "#1a1111"; # Fundo escuro quente, compatível com Ambxst default
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
