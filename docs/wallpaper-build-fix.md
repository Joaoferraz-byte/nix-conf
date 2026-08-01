# Nota técnica: Falha de build do SDDM por wallpaper ausente no store

## Sintoma

Após a migração do tema SDDM de Pixie-SDDM para SilentSDDM (commit `c805f78`, 2026-07-31), o comando `nixos-rebuild switch --flake .#myMachine` passou a falhar com:

```
warning: Git tree '/home/livara/.config/nixos' is dirty
...
cp: cannot stat '.../source/Wallpapers/wallhaven-9or3zx.jpg': No such file or directory
```

A derivação `silent-unknown` (nome `silent` + versão `unknown`, pois o módulo NixOS não passa `gitRev`) falhava durante sua `installPhase`, quando tentava copiar o wallpaper `wallhaven-9or3zx.jpg` para dentro do tema SDDM. A cascata de dependências era: `silent-unknown → sddm.conf → system-path → nixos-system`.

## Causa Raiz

A migração Pixie-SDDM → SilentSDDM alterou o mecanismo de referência a wallpapers de uma **derivação intermediária** para um **path de filesystem direto**.

### Antes (Pixie SDDM, commit `b25e607`):

```nix
assets = pkgs.runCommand "ambxst-sddm-assets" {} ''
  mkdir -p $out/background $out/avatar
  cp ${./Icons/6afde16e1ef1cb3257b30e01890787dd.jpg} $out/avatar/avatar.jpg
  cp ${./Wallpapers/wallhaven-9or3zx.jpg} $out/background/background.jpg
'';
pixieTheme = inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
  background = assets + "/background/background.jpg";
  avatar = assets + "/avatar/avatar.jpg";
  ...
};
```

Essa abordagem criava uma **derivação** que copiava os wallpapers para o Nix store durante o build. O resultado era um store path sempre disponível, independente do estado do tree local.

### Depois (SilentSDDM, commit `c805f78`):

```nix
programs.silentSDDM = {
  backgrounds = {
    "wallhaven-9or3zx.jpg" = self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg";
  };
  profileIcons.livara = self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg";
};
```

Essa abordagem passa um **path de filesystem diretamente** para a opção `backgrounds`. O SilentSDDM, em seu `installPhase`, executa `cp ${bg}` dentro do sandbox do build. Quando o flake é avaliado a partir de um working tree sujo (warning "Git tree is dirty"), `self.outPath` resolve para o diretório local (`/home/livara/.config/nixos`). Se o arquivo não existe nesse caminho local (por exemplo, o clone não foi atualizado ou o arquivo foi removido localmente), o `cp` falha.

### Por que o arquivo "some" localmente:

O arquivo `Wallpapers/wallhaven-9or3zx.jpg` está rastreado no git desde o commit raiz (`544dab0`, 2026-07-26) e está presente em todos os commits do branch `main`. No entanto, o usuário pode não ter o arquivo no working tree local por:

1. **Clone não atualizado**: O repositório local pode não ter recebido o `git pull` mais recente.
2. **Arquivo removido localmente**: O arquivo pode ter sido deletado acidentalmente do working tree sem commit.
3. **Tree sujo com arquivo ausente**: O warning "Git tree is dirty" indica que o working tree não está limpo; se o arquivo foi removido localmente mas o commit no git o inclui, o Nix ainda tenta acessar o path local.

### Por que a derivação anterior funcionava:

A derivação `pkgs.runCommand` copiava o arquivo durante o **build**, não durante a **avaliação**. O sandbox do build do Nix permite acesso ao path do flake source (mesmo que seja o working tree local), mas a derivação garantiia que o resultado estivesse no store. O SilentSDDM, por outro lado, referencia o path diretamente e espera que o arquivo exista no caminho especificado durante seu próprio build.

## Decisão e Correção

A solução re-introduz uma derivação intermediária no `greeter.nix`, restaurando o padrão robusto que funcionava com o Pixie SDDM:

### `modules/features/greeter.nix`:

```nix
{ self, inputs, pkgs, ... }: let
  assets = pkgs.runCommandNoCC "nix-conf-sddm-assets" {} ''
    mkdir -p $out/backgrounds $out/icons
    cp ${self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg"} $out/backgrounds/wallhaven-9or3zx.jpg
    cp ${self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg"} $out/icons/avatar.jpg
  '';
in {
  programs.silentSDDM = {
    backgrounds = {
      "wallhaven-9or3zx.jpg" = assets + "/backgrounds/wallhaven-9or3zx.jpg";
    };
    profileIcons.livara = assets + "/icons/avatar.jpg";
  };
}
```

### `home/livara/home.nix`:

O `home.nix` também referenciava `self.outPath` diretamente para o ícone de perfil (`~/.face.icon`) e para o symlink do diretório `Wallpapers`. Ambos foram corrigidos usando `builtins.path`, que força a cópia do diretório para o Nix store durante a avaliação do flake, eliminando a dependência do estado do tree local:

```nix
let
  iconsPath = builtins.path {
    path = self.outPath + "/Icons";
    name = "nix-conf-icons";
  };
  wallpapersPath = builtins.path {
    path = self.outPath + "/Wallpapers";
    name = "nix-conf-wallpapers";
  };
  profileIcon = iconsPath + "/6afde16e1ef1cb3257b30e01890787dd.jpg";
in {
  home.file.".face.icon".source = profileIcon;
  home.file.".config/nixos/Wallpapers".source = wallpapersPath;
}
```

A escolha entre `runCommandNoCC` (no greeter) e `builtins.path` (no home.nix) reflete as diferenças de contexto: no `greeter.nix`, o `pkgs.runCommandNoCC` é mais apropriado porque precisa copiar arquivos específicos para subdiretórios (`backgrounds/`, `icons/`) que o SilentSDDM espera. No `home.nix`, o `builtins.path` é mais simples porque o Home Manager aceita um diretório inteiro como source do symlink.

## Verificação

O usuário deve:

1. **Garantir que o working tree local está limpo**:
   ```bash
   cd ~/.config/nixos
   git pull origin main
   git status   # deve mostrar "nothing to commit, working tree clean"
   ```

2. **Reconstruir o sistema**:
   ```bash
   sudo nixos-rebuild switch --flake .#myMachine
   ```

3. **Confirmar ausência de erros**:
   - O warning "Git tree is dirty" não deve aparecer (se o tree está limpo).
   - A derivação `silent-*` deve construir com sucesso.
   - O wallpaper deve aparecer na tela de login do SDDM.

## Referências

[1]: https://github.com/Joaoferraz-byte/nix-conf "Repositório nix-conf"
[2]: https://github.com/uiriansan/SilentSDDM "Repositório SilentSDDM"
[3]: https://wiki.nixos.org/wiki/Nix_Flips "Nix Flakes — self.outPath e avaliação"
