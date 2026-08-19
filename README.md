# nix-conf

`nix-conf` é a raiz declarativa de dois hosts NixOS, com uma composição compartilhada de **niri**, Home Manager, Noctalia, NixVim e serviços de desktop. O objetivo é manter o mesmo contrato de sessão entre notebook e computador, deixando diferenças limitadas a hardware, layout de teclado e política de energia.

## Hosts

| Host | Perfil | Diferenças intencionais |
|---|---|---|
| `latitude` | Notebook | Layout interno irlandês, teclado externo brasileiro via keyd, energia Intel, Wi-Fi/Bluetooth e escala do painel interno. |
| `myMachine` | Desktop | GPU, Btrfs/virtualização e descoberta dinâmica de monitores; nenhum output fictício é declarado. |

A composição comum está em `modules/hosts/common-desktop.nix`. Ela importa o módulo oficial do [Noctalia](https://github.com/noctalia-dev/noctalia), a API Home Manager do [shell-conf](https://github.com/Joaoferraz-byte/shell-conf), NixVim e os módulos de host. NixOS é o owner do compositor, input, portais, drivers e serviços privilegiados; Home Manager é o owner dos arquivos e serviços da sessão do usuário.

## Sessão visual

**niri é o único compositor ativo. Noctalia é o único shell visual.** O arquivo `home/livara/niri.nix` instala um `config.kdl` com XKB, navegação, workspaces, fullscreen, screenshot nativo e chamadas IPC documentadas do Noctalia. `home/livara/monitors.nix` instala apenas `outputs.kdl`: a latitude recebe a escala do painel conhecido e o myMachine usa descoberta dinâmica, portanto não reserva um segundo monitor.

O launcher e os painéis são abertos por IPC do Noctalia. Em particular, `Super+Space` abre o launcher, `Super+Shift+W` abre o seletor de wallpaper, `Super+Shift+S` usa a ação nativa de screenshot e `Super+F` alterna fullscreen. Não existe um segundo bar, daemon de wallpaper ou processo de shell concorrente no perfil.

## Temas por ecossistema

O [shell-conf](https://github.com/Joaoferraz-byte/shell-conf) expõe `programs.livara.visual`. Ele não é um shell: fornece templates Matugen, uma paleta dark-only derivada do wallpaper e o comando `sync-livara-themes`. Noctalia seleciona o wallpaper em `~/Wallpapers`, entrega `NOCTALIA_WALLPAPER_PATH` ao hook, Matugen gera a paleta mutável em `$XDG_STATE_HOME/livara/theme` e cada adapter materializa o formato específico do aplicativo.

ZenNotes recebe `themes/livara/manifest.json` e `theme.css`; Firefox e Zen Browser recebem `userChrome.css`/`userContent.css`; GTK, Qt, WezTerm, Neovim, Cava, Tauon, Freesm Launcher, Vesktop e Xournal++ recebem seus contratos próprios. A existência de um template não é contada como aplicação do tema: o manifesto `applied-applications.json` registra os caminhos realmente materializados. O modo é sempre dark e não há integração Catppuccin.

## Teclado e aplicações

O XKB do niri usa o layout definido pelo host. A latitude seleciona `ie` para o teclado interno; a camada keyd é restringida aos IDs do Aitek Delta TM6101 e fornece os atalhos de navegação/pontuação do teclado externo. O myMachine usa o padrão `br(abnt2)`. O console, XKB do sistema e XKB do niri são camadas distintas e precisam manter o mesmo objetivo sem duplicar keybinds.

`home/livara/sync.nix` sincroniza `~/Wallpapers` e `~/Vault` com timers independentes. O wrapper `zennotes-livara` faz pull antes de abrir ZenNotes e executa `git add`, commit e push no encerramento normal; o serviço de sessão também tenta salvar no logout/desligamento gracioso. Uma perda abrupta de energia não pode executar código depois do corte e, portanto, não é prometida como garantia impossível.

## Validação

A validação progressiva recomendada é:

```bash
git diff --check
find src modules -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
sudo nix --extra-experimental-features 'nix-command flakes' flake check --no-build --show-trace --all-systems
sudo nix --extra-experimental-features 'nix-command flakes' flake check --no-build --show-trace \
  --override-input shell-conf path:../shell-conf
niri validate --config ~/.config/niri/config.kdl
```

O check local dos dois hosts foi executado sem build. A avaliação apresentou somente warnings existentes de Nixpkgs/Home Manager e de outputs customizados; não apresentou erro de opção inexistente. Builds completos e `nixos-rebuild test` ainda devem ser executados no hardware real antes de uma troca permanente.
