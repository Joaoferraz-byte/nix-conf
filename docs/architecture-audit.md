# Livara architecture audit

**Data:** 2026-10-02
**Escopo:** `nix-conf`, `ambxst-conf`, `shell-conf` e `vim-conf`
**Restrição operacional:** nenhum build ou `nixos-rebuild` foi executado.

## Contrato ativo confirmado

A composição ativa em `modules/hosts/common-desktop.nix` importa `ambxst-conf`, `shell-conf` e `vim-conf`. O `nix-conf/flake.nix` não importa `noctalia-conf`; esse repositório foi apenas inspecionado e não foi alterado porque não participa do grafo ativo. O contrato resultante é:

> Ambxst produz a paleta escura canônica → `shell-conf` publica projeções documentadas → NixVim e os aplicativos consomem essas projeções.

`nix-conf` continua sendo o único dono da configuração e do reload do Niri. `ambxst-conf` continua sendo o dono do runtime Ambxst e de seus diretórios mutáveis. `shell-conf` não inicia shell, compositor ou IPC de compositor.

## Achados e correções

| Achado | Evidência atualizada | Correção aplicada | Motivo verificável |
| --- | --- | --- | --- |
| `dark_mode` era atribuído mas nunca lido no `sync_gtk_theme`; o `writeShellApplication` parava no ShellCheck SC2034. | Erro recebido: `sync-livara-themes.sh:378`; implementação em `shell-conf/modules/support.nix`. | Removida a atribuição morta; o perfil já é explicitamente dark-only. | [ShellCheck SC2034](https://www.shellcheck.net/wiki/SC2034) define a atribuição sem leitura como provável erro. |
| O orquestrador também mantinha `variant=dark` sem consumo. | `shell-conf/modules/support.nix`. | Removida a variável e o argumento passou a ser literal onde o contrato exige dark. | Evita outro SC2034 e deixa o contrato visível no ponto de chamada. |
| Ponte Ambxst e adaptador de aplicativos geravam os mesmos formatos de WezTerm e Neovim. | Antes: `sync-ambxst-palette.sh` escrevia `wezterm/Ambxst.toml` e `nvim/lua/matugen_colors.lua`; `sync-livara-themes.sh` também escrevia esses destinos. | A ponte agora escreve somente `palette.dark.json` e `palette.json`; `sync-livara-themes.sh` é o único escritor das projeções de aplicativos. | Uma saída mutável tem um escritor; o teste `test-ambxst-palette-bridge.sh` verifica a ausência das projeções duplicadas. |
| Duas chamadas podiam alterar a mesma árvore durante uma atualização de wallpaper. | Serviço `sync-all-livara-themes`, `PathChanged` e chamadas manuais compartilhavam `$XDG_STATE_HOME/livara/theme`. | Ponte, adaptadores e orquestrador usam o mesmo `flock`; o orquestrador mantém o lock durante as duas fases. | O teste `test-theme-lock.sh` mantém o lock e confirma que nenhuma saída é criada. |
| `shell-conf` recarregava `axctl` e Niri, enquanto `nix-conf` já observava `axctl.generated.kdl` e recarregava Niri. | `nix-conf/home/livara/niri.nix` é o watcher do arquivo gerado; `shell-conf/modules/support.nix` era o segundo caminho. | Removido o reload de compositor do shell; mantido apenas o watcher declarativo de `nix-conf`. | Elimina reload duplicado e respeita a fronteira documentada de `shell-conf` como camada sem compositor. |
| O perfil foi convertido para dark-only, mas o Home Manager ainda semeava `palette.light.json` e a documentação descrevia dois modos. | `shell-conf/modules/support.nix`, READMEs e exemplos de paleta. | A ativação semeia apenas `palette.json` e `palette.dark.json`; textos e exemplos agora declaram dark-only. | Evita que um arquivo de variante obsoleto seja confundido com saída ativa. |
| O editor mantinha dois caminhos para a mesma paleta, embora o escritor ativo já usasse apenas `nvim/lua/matugen_colors.lua`. | `vim-conf/config/theme.nix` e `shell-conf/src/livara/scripts/sync-livara-themes.sh`. | NixVim consome somente o caminho canônico. | Reduz fallback legado e torna o contrato entre repositórios explícito. |
| Documentação do editor e do shell ainda atribuía a paleta a Noctalia/Matugen. | `vim-conf/ARCHITECTURE_PROPOSAL.md`, `vim-conf/README.md`, `shell-conf/README.md` e guia de runtime. | Referências ativas foram atualizadas para Ambxst; menções negativas em checks do NixOS foram preservadas apenas como verificações de ausência de processos antigos. | A fonte real está em `ambxst-conf/README.md` e no grafo de `nix-conf`. |

## Padrões preservados

- `nix-conf` continua com um único `config.kdl` declarativo e um único watcher de `axctl.generated.kdl`.
- `stylix.targets.gtk/qt.enable = false` permanece: a paleta dinâmica é escrita pelo adaptador, enquanto Stylix continua fornecendo integrações não conflitantes, cursor e pacotes.
- GTK/libadwaita e Qt continuam com seus próprios contratos; o sincronizador só escreve formatos documentados, como CSS GTK, `kdeglobals`, userChrome e o esquema TOML do WezTerm. Ver [GTK CSS](https://docs.gtk.org/gtk4/css-overview.html), [Qt Style Sheets](https://doc.qt.io/qt-6/stylesheet.html) e [WezTerm appearance](https://wezterm.org/config/appearance.html).
- `ambxst-conf` não foi reescrito: seu `README.md` já declara que Ambxst é o dono do runtime, da paleta de cache e do arquivo `axctl.generated.kdl`.

## Validação executada sem build

- `bash -n` em scripts modificados e testes.
- Testes focados de contratos da ponte, adapters e lock compartilhado.
- `git diff --check` em cada repositório.
- Revisão cruzada de `common-desktop.nix`, `niri.nix`, `support.nix`, `ambxst-conf/README.md` e dos contratos de saída.

A validação de `nix flake check --no-build` continua sendo apropriada como próxima verificação de avaliação, mas não substitui a validação visual no host real e não materializa o toplevel NixOS.
