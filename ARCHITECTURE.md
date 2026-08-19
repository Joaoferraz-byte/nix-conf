# Arquitetura do `nix-conf`

## Escopo

`nix-conf` é a raiz de composição declarativa dos hosts NixOS. O flake-parts publica configurações de sistema e features por domínio; Home Manager compõe o ambiente do usuário; inputs externos fornecem módulos especializados. A sessão gráfica possui um único compositor e um único shell visual.

> **Um owner por concern, uma closure explícita por serviço e um contrato público entre repositórios.**

NixOS é owner de niri, XKB do sistema, keyd, portais, drivers, rede, áudio e serviços privilegiados. Home Manager é owner de programas de usuário, arquivos XDG e serviços user-level. Noctalia é owner da superfície visual, launcher, painéis, notificações, wallpaper e IPC. `shell-conf` é owner dos templates Matugen e dos adapters de temas por aplicação. `vim-conf` é owner do NixVim; `xournal-conf` é owner dos arquivos editáveis de Xournal++; `Wallpapers` é owner do catálogo de imagens.

## Fluxo de composição

```text
flake inputs
  -> flake-parts feature modules
    -> host roots
      -> common desktop profile
        -> Home Manager user profile
          -> niri config + Noctalia module + Livara visual API
```

A composição passa por `extraSpecialArgs` somente os dados de integração necessários (`inputs`, usuário e perfil tipado). O compositor não é encaminhado como flag para o shell: o perfil aceita apenas `niri`, e as ações da interface são expressas como ações nativas do niri ou IPC documentado do Noctalia.

| Host | Layout principal | Política de output |
|---|---|---|
| `latitude` | `ie` no teclado interno; Aitek externo tratado pelo keyd | Escala declarativa do painel `desc:BOE 0x07BB`. |
| `myMachine` | `br(abnt2)` | Descoberta dinâmica; `outputs.kdl` vazio. |

## Fronteiras de repositório

| Repositório/input | Contrato público | Owner |
|---|---|---|
| `nix-conf` | Hosts, módulos NixOS, composição Home Manager e políticas de sessão | Sistema e integração |
| `shell-conf` | `homeManagerModules.default`, `programs.livara.visual`, templates e adapters Matugen | Visual por aplicação |
| `noctalia` | `inputs.noctalia.homeModules.default` e IPC `noctalia msg` | Shell visual |
| `vim-conf` | Módulo NixVim, plugins e keymaps | Editor |
| `xournal-conf` | XML, INI, TeX e defaults do Xournal++ | Aplicação de notas |
| `Wallpapers` | Imagens | Catálogo de assets |

O flake do shell-conf não contém input de QuickShell, não publica módulo NixOS de shell, não instala daemon de wallpaper e não escreve configurações de compositor. O flake do nix-conf não importa módulo Hyprland.

## Sessão niri e Noctalia

`modules/features/niri.nix` habilita niri e os pacotes mínimos do ambiente Wayland. `home/livara/niri.nix` é o owner único do `~/.config/niri/config.kdl`, da navegação, workspaces, fullscreen, screenshot, hardware keys e bind IPC do Noctalia. `home/livara/monitors.nix` materializa somente `outputs.kdl` e nunca declara um monitor fictício.

O workspace numérico é verificado por um pequeno helper baseado em `niri msg --json workspaces`; se o índice não existe, nenhuma ação é emitida. Isso preserva a semântica dinâmica do niri e evita que a interface crie workspaces vazios como uma lista fixa. A surface visual não consulta `hyprctl`, não possui QML de barra e não inicia um segundo lifecycle.

| Concern | Owner |
|---|---|
| Login e compositor | NixOS niri + display manager |
| Input/XKB e remapeamento específico | NixOS XKB + keyd |
| Idle/lock/monitor power | `home/livara/session.nix` + hypridle independente |
| Bar, panels, launcher e wallpaper picker | Noctalia |
| Wallpaper catalog | `home/livara/sync.nix` + repositório Wallpapers |
| Dynamic theme generation | Matugen executado pelo hook do Noctalia |
| Application theme adapters | `shell-conf` / `sync-livara-themes` |

## API visual Livara

O módulo declara somente:

```nix
programs.livara.visual = {
  enable = true;
  wallpaperDirectory = "/home/livara/Wallpapers";
  themeName = "Livara";
};
```

A closure instala Matugen, jq e os adapters necessários. Templates imutáveis vivem no Nix store; resultados gerados vivem em `$XDG_STATE_HOME/livara/theme`. O hook do Noctalia recebe `NOCTALIA_WALLPAPER_PATH`, executa Matugen em modo dark, grava a paleta e chama o sincronizador. A atualização de todos os arquivos usa temporário e `mv` atômico onde o contrato da aplicação permite.

Cada aplicação mantém seu próprio ecossistema:

| Aplicação/ecossistema | Saída gerada |
|---|---|
| Noctalia | `~/.config/noctalia/palettes/Livara.json` |
| GTK/Nautilus | CSS GTK3/GTK4 e prefer-dark via dconf |
| Qt | qt5ct/qt6ct e QSS |
| WezTerm/Kitty | Módulos Lua/conf nativos |
| Neovim | Módulo Lua Matugen carregável pelo NixVim |
| Firefox/Zen Browser | `userChrome.css`, `userContent.css` e `user.js` |
| ZenNotes | `themes/livara/manifest.json` + `theme.css` |
| Tauon/Freesm Launcher | Tema nativo/Qt específico |
| Vesktop | CSS local e `settings.json.enabledThemes` |
| Xournal++ | Paleta GIMP `.gpl` + `colorPalette` |

Não se afirma compatibilidade Stylix quando a aplicação não possui contrato Stylix. Stylix pode cuidar de integrações que ele suporta; Matugen/adapters cuidam das demais. Não há fonte Catppuccin e a presença de tokens legados em algum formato não é uma dependência de pacote.

## Estado e segurança

A avaliação constrói closures e referências ao store; a realização ocorre no Home Manager, systemd e nos programas de sessão. Dados mutáveis — paletas, CSS de perfil, checkouts do Vault e wallpapers — permanecem fora do store. A ativação não faz downloads nem `git pull`; timers e serviços independentes fazem sincronização depois que a sessão está disponível.

O wrapper ZenNotes faz pull antes da abertura e tenta `git add`, commit e push depois do encerramento normal. O serviço de sessão repete o save durante o teardown gracioso. Perda súbita de energia, reset forçado ou kernel panic não permitem executar um `ExecStop`, portanto não podem ser garantidos por systemd.

## Validação

A sequência deve ser executada em etapas:

```bash
git diff --check
find src modules -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
sudo nix --extra-experimental-features 'nix-command flakes' flake check --no-build --show-trace --all-systems
sudo nix --extra-experimental-features 'nix-command flakes' flake check --no-build --show-trace \
  --override-input shell-conf path:../shell-conf
nix-store --verify --check-contents   # opcional, fora do ciclo de avaliação
niri validate --config ~/.config/niri/config.kdl
```

A avaliação atual dos dois hosts e a validação KDL de latitude/myMachine passaram sem erro de opções inexistentes. Warnings de depreciação do nixpkgs/Home Manager e de outputs customizados não são falhas de avaliação; devem ser tratados em uma atualização futura, separada da migração arquitetural.

## Referências

[1]: https://mhwombat.codeberg.page/nix-book/ "Mhwombat Nix Book"
[2]: https://edolstra.github.io/pubs/phd-thesis.pdf "The Purely Functional Software Deployment Model"
[3]: https://ekala-project.github.io/nix-book/ "Ekala Nix Book"
[4]: https://saylesss88.github.io/ "Saylesss88 Nix Book"
[5]: https://wiki.nixos.org/wiki/Niri "NixOS Wiki — Niri"
[6]: https://github.com/noctalia-dev/noctalia-shell "Noctalia Shell"
[7]: https://github.com/InioX/matugen "Matugen"
[8]: https://github.com/rvaiya/keyd "keyd"
