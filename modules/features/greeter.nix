# ─── SDDM Display Manager + SilentSDDM ──────────────────────────────────────
# O módulo oficial do SilentSDDM empacota o tema e todas as dependências Qt
# necessárias. O avatar é publicado pelo AccountsService, portanto é acessível
# ao greeter antes do login e não precisa ser copiado para dentro do tema.
#
# WALLPAPERS: Usamos uma derivação (pkgs.runCommandNoCC) para copiar os
# wallpapers do repositório para o Nix store. Isso é necessário porque
# self.outPath pode apontar para o working tree local quando o flake é
# avaliado com "Git tree is dirty"; o installPhase do SilentSDDM executa
# `cp ${bg}` dentro do sandbox do build e falha se o arquivo não existir
# no caminho de filesystem local. A derivação garante que o arquivo esteja
# sempre no store, independente do estado do tree local.
# Ver: docs/wallpaper-build-fix.md
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, config, ... }: let
    # Derivação que copia wallpapers e ícones para o Nix store.
    # Definida dentro do módulo para ter acesso ao `pkgs` do sistema.
    assets = pkgs.runCommandNoCC "nix-conf-sddm-assets" {} ''
      mkdir -p $out/backgrounds $out/icons
      cp ${self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg"} $out/backgrounds/wallhaven-9or3zx.jpg
      cp ${self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg"} $out/icons/avatar.jpg
    '';
  in {
    imports = [
      inputs.silentSDDM.nixosModules.default
    ];

    programs.silentSDDM = {
      enable = true;
      theme = "default";

      # Preserva o wallpaper que já era usado pelo greeter anterior; a migração
      # altera apenas o tema e o mecanismo de ícone de perfil.
      backgrounds = {
        "wallhaven-9or3zx.jpg" = assets + "/backgrounds/wallhaven-9or3zx.jpg";
      };

      # Fonte única para o ícone do SDDM. O mesmo ativo é declarado em home.nix
      # como ~/.face.icon.
      profileIcons.livara = assets + "/icons/avatar.jpg";

      settings = {
        LoginScreen.background = "wallhaven-9or3zx.jpg";
        LockScreen.background = "wallhaven-9or3zx.jpg";
      };
    };
  };
}
