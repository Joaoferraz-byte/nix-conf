# nix-conf

`nix-conf` é a raiz declarativa de dois hosts NixOS, com uma composição compartilhada de **niri**, Home Manager, **DankMaterialShell (DMS) v1.5.3**, NixVim e serviços de desktop. O objetivo é manter o mesmo contrato visual e de sessão entre notebook e computador, deixando diferenças limitadas a hardware, layout de teclado e política de energia.

## Hosts

| Host | Perfil | Diferenças intencionais |
|---|---|---|
| `latitude` | Notebook | Layout interno irlandês, teclado externo brasileiro via keyd, bateria/energia, Wi-Fi/Bluetooth e escala do painel interno. |
| `myMachine` | Desktop | GPU, Btrfs/virtualização, mesa digitalizadora e descoberta dinâmica de monitores; não reserva output fictício nem exibe controles de bateria/Bluetooth. |

A composição comum está em `modules/hosts/common-desktop.nix`. NixOS é o owner do compositor, input, portais, drivers e serviços privilegiados; Home Manager é o owner dos arquivos e serviços da sessão do usuário. O módulo visual do `shell-conf` é injetado pelo Home Manager e configura o DMS pinado pelo flake host.

## Sessão visual

**niri é o único compositor ativo e DMS v1.5.3 é o único shell visual.** `home/livara/niri.nix` instala o `config.kdl` com XKB por host, navegação de janelas, workspaces, fullscreen, screenshot nativo e chamadas IPC documentadas do DMS. `home/livara/monitors.nix` instala apenas `outputs.kdl`: a Latitude recebe a escala do painel conhecido e `myMachine` usa descoberta dinâmica, portanto não reserva um segundo monitor.

O serviço oficial `programs.dank-material-shell.systemd` inicia o shell; niri não inicia uma segunda instância. O launcher e os painéis são abertos por IPC do DMS. Em particular, `Super+Space` abre o launcher, `Super+W` abre o Zen Browser, `Super+E` abre o Nautilus, `Super+F` alterna fullscreen, `Super+Shift+W` chama `dms ipc call wallpaperCarousel toggle`, `Super+Shift+S` usa a ação nativa de screenshot e `Super+S` alterna o Control Center. O plugin `wallpaperCarousel` é pinado como input do flake e recebe declarativamente `~/Wallpapers`; o serviço de login continua selecionando um wallpaper aleatório via `dms ipc call wallpaper set`, depois do qual DMS/Matugen deriva a paleta.

## Temas por ecossistema

O `shell-conf` fornece o módulo Home Manager e os adapters que não são cobertos pelos templates nativos do DMS. O fluxo correto é:

> Wallpaper em `~/Wallpapers` → DMS/Matugen nativo → `~/.cache/DankMaterialShell/dms-colors.json` → `livara-matugen-sync` → contratos específicos de cada aplicativo.

DMS v1.5.3 permanece owner de GTK, Qt, Firefox, Zen Browser, WezTerm, Vesktop, Kitty e NixVim quando os respectivos `matugenTemplate*` estão habilitados. O shell-conf apenas liga os CSS de browser aos perfis reais e não substitui os arquivos gerados pelo DMS. Ele mantém apenas ZenNotes, Tauon, Freesm Launcher e Xournal++, cada um no formato documentado pelo próprio ecossistema. Foliate recebe o tema GTK; Heroic não possui um contrato Matugen nativo equivalente e não recebe CSS especulativo.

Para ZenNotes, o adapter cria `themes/nix-conf-matugen/manifest.json` e `theme.css` em `~/.config/zennotes` e, quando a instalação Flatpak está presente, em `~/.var/app/org.zennotes.ZenNotes/config/zennotes`. O CSS usa tokens `--z-*` como triplets RGB separados por espaço e `config.toml` seleciona o tema em modo dark. O manifesto `applied-applications.json` diferencia templates nativos do DMS de adapters realmente materializados. Não há integração Catppuccin.

O modo visual é sempre dark. `stylix` é usado para o cursor Bibata em toda a sessão; ele não substitui contratos que um aplicativo não suporta. Assim, a origem das cores é centralizada no DMS/Matugen, enquanto o formato final continua sendo responsabilidade de cada aplicativo.

## Plugins declarativos

`wallpaperCarousel` é instalado pelo módulo DMS a partir do input pinado `motor-dev/wallpaperCarousel`, com modo wrap, cache limitado, expansão da imagem em foco e `~/Wallpapers` como diretório. `nix-monitor` é instalado pelo seu módulo Home Manager oficial, com `config.json`, contador de gerações, tamanho do store e widget `nixMonitor` na barra; o comando de rebuild é host-aware. O calendário continua usando o backend nativo `khal`, mas `ikhal` é colocado na lista de aplicativos ocultos do `SessionData` do DMS.

## Integrações de produtividade

O calendário nativo do DMS permanece habilitado. Tasks complementares do Vault ZenNotes são indexadas por `livara_zennotes_tasks.py`, armazenadas em `~/.local/state/livara/zennotes-tasks.json` e exibidas pelo plugin QML Livara no widget da barra e no provider `/tasks` do launcher. A integração não substitui o calendário nem tenta tratar tasks como eventos de um backend de calendário.

No `myMachine`, o plugin também expõe o estado da mesa digitalizadora e a abertura de uma nota diária Xournal++ em `~/Vault/02 - Xournal++`. No Latitude, bateria e Bluetooth permanecem habilitados; no desktop, esses controles são omitidos por host conditionals.

## Teclado, Vault e sincronização

O XKB do niri usa o layout declarado pelo host. A Latitude seleciona `ie` para o teclado interno; a camada keyd é restringida aos IDs do Aitek Delta TM6101 e fornece a camada de atalhos/pontuação do teclado externo. `myMachine` usa `br(abnt2)`. Console, XKB do sistema, XKB do niri e keyd são camadas distintas e devem manter objetivos coerentes sem duplicar keybinds.

`home/livara/sync.nix` sincroniza `~/Wallpapers` e `~/Vault` com timers independentes. O wrapper `zennotes-livara` faz pull antes de abrir ZenNotes e executa `git add`, commit e push no encerramento normal; o serviço de sessão também tenta salvar no logout/desligamento gracioso. Uma perda abrupta de energia não pode executar código depois do corte e, portanto, não é prometida como garantia impossível.

## Validação progressiva

Antes de um rebuild completo, use as seguintes gates:

```bash
git diff --check
find ../shell-conf/src ../shell-conf/modules -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
sudo nix --extra-experimental-features 'nix-command flakes' flake check --no-build --show-trace --all-systems
sudo nix --extra-experimental-features 'nix-command flakes' flake check --no-build --show-trace \
  --override-input shell-conf path:../shell-conf
niri validate --config ~/.config/niri/config.kdl
```

A avaliação declarativa dos hosts `myMachine` e `latitude` foi executada com os inputs dos novos plugins e passou sem erro de opção; `flake check --no-build` também passou. No `myMachine`, o hardware-configuration mantém somente o swap real `73f0052c-6927-45c4-b3a2-8cdc4cbd0d8b`; o UUID inexistente `79febc52-42dd-4d8e-ba13-eea976778dfb` foi removido, eliminando o timeout de boot de 90 segundos após a aplicação da nova geração. A validação declarativa não prova que DMS, compositor, áudio, cursor ou widgets estão visualmente funcionais no hardware; o gate final deve ser `sudo nixos-rebuild test --flake .#<host>`, seguido por checagens de `dms doctor`, unidades systemd do usuário, wallpaper, cursor e contratos gerados.
