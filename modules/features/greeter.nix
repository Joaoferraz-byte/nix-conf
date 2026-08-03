# ─── SDDM Display Manager + SilentSDDM ──────────────────────────────────────
# O módulo oficial do SilentSDDM empacota o tema e todas as dependências Qt
# necessárias. O avatar é publicado pelo AccountsService, portanto é acessível
# ao greeter antes do login e não precisa ser copiado para dentro do tema.
#
# ASSETS: Usamos caminhos relativos em vez de self.outPath para evitar erros
# de "pure evaluation" no Nix Flakes. O Nix copia automaticamente os arquivos
# referenciados por caminhos relativos para o store durante a avaliação.
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, config, ... }: let
    # Derivação que copia apenas o ícone de perfil para o Nix store.
    # O wallpaper foi removido conforme solicitação do usuário (o tema não
    # foi feito para isso).
    assets = pkgs.runCommandNoCC "nix-conf-sddm-assets" {} ''
      mkdir -p $out/icons
      cp ${../../Icons/6afde16e1ef1cb3257b30e01890787dd.jpg} $out/icons/avatar.jpg
    '';
  in {
    imports = [
      inputs.silentSDDM.nixosModules.default
    ];

    programs.silentSDDM = {
      enable = true;
      theme = "default";

      # O wallpaper foi removido deste bloco pois o tema SilentSDDM não deve
      # ser forçado a usar um background customizado via Nix se não for
      # suportado nativamente ou se causar problemas de layout.
      backgrounds = {};

      # Fonte única para o ícone do SDDM. O mesmo ativo é declarado em home.nix
      # como ~/.face.icon.
      profileIcons.livara = assets + "/icons/avatar.jpg";

      settings = {
        # Configurações de background removidas para evitar erros no tema.
      };
    };
  };
}
