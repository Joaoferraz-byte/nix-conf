# ─── SDDM Display Manager + SilentSDDM ──────────────────────────────────────
# O módulo oficial do SilentSDDM empacota o tema e todas as dependências Qt
# necessárias. O avatar é publicado pelo AccountsService, portanto é acessível
# ao greeter antes do login e não precisa ser copiado para dentro do tema.
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { ... }: {
    imports = [
      inputs.silentSDDM.nixosModules.default
    ];

    programs.silentSDDM = {
      enable = true;
      theme = "default";

      # Preserva o wallpaper que já era usado pelo greeter anterior; a migração
      # altera apenas o tema e o mecanismo de ícone de perfil.
      backgrounds = {
        "wallhaven-9or3zx.jpg" = self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg";
      };

      # Fonte única para o ícone do SDDM. O mesmo ativo é declarado em home.nix
      # como ~/.face.icon, que é o caminho lido pelo Ambxst-X na sessão gráfica.
      profileIcons.livara = self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg";

      settings = {
        LoginScreen.background = "wallhaven-9or3zx.jpg";
        LockScreen.background = "wallhaven-9or3zx.jpg";
      };
    };
  };
}
