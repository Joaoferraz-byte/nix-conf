# Xournal++ declarativo via nix-conf

O Xournal++ é instalado pelo `nix-conf`, enquanto os arquivos de configuração próprios são versionados no repositório [`Joaoferraz-byte/xournal-conf`](https://github.com/Joaoferraz-byte/xournal-conf). O `flake.nix` declara esse repositório como um input não-flake. Os arquivos `settings.xml` e `toolbar.ini` são inicializados em `~/.config/nixos/xournalpp/` e ligados para `~/.config/xournalpp/` por meio de symlinks fora do Nix store; assim, o Xournal++ pode gravar alterações neles normalmente.

| Fonte em `xournal-conf` | Destino declarativo |
| --- | --- |
| `xournalpp/settings.xml` | `~/.config/nixos/xournalpp/settings.xml` → `~/.config/xournalpp/settings.xml` |
| `xournalpp/toolbar.ini` | `~/.config/nixos/xournalpp/toolbar.ini` → `~/.config/xournalpp/toolbar.ini` |
| `xournalpp/default_template.tex` | `/home/livara/.config/xournalpp/default_template.tex` |
| `xournalpp/palettes/tokyo-night.gpl` | `/home/livara/.config/xournalpp/palettes/tokyo-night.gpl` |

O `settings.xml` seleciona o perfil personalizado **Xournal++ Copy**, o tema geral `useSystem`, o template LaTeX versionado e a paleta Tokyo Night. O template mantém os placeholders `%%XPP_TEXT_COLOR%%` e `%%XPP_TOOL_INPUT%%`, que o Xournal++ substitui ao gerar cada fórmula. A paleta possui 11 cores claras para manter contraste sobre páginas com fundo preto puro.

Depois de editar as opções pela interface do Xournal++, execute `scripts/sync-xournalpp-config.sh /caminho/para/xournal-conf` no checkout do repositório. Revise o diff e então faça commit e push. A ativação do Home Manager só copia os arquivos do input quando eles ainda não existem, portanto não sobrescreve customizações locais.

O carregamento correto do template depende de `latexSettings.globalTemplatePath` apontar para o arquivo instalado em `~/.config/xournalpp/default_template.tex`. A configuração anterior apontava para um caminho Nix/Matugen que não existia no fluxo não gerado; esse caminho foi removido. O esquema `classic` do editor LaTeX é selecionado por ser um esquema fornecido pelo próprio GtkSourceView, sem depender de um arquivo Matugen não instalado.

A lógica de Matugen do DMS não é usada para os arquivos deste repositório. O DMS continua responsável apenas por seus próprios temas; o Xournal++ é totalmente reproduzido pelo input do flake e pelo Home Manager.

## Referências

1. [Xournal++ file locations](https://xournalpp.github.io/guide/file-locations/)
2. [Xournal++ LaTeX tool](https://xournalpp.github.io/guide/tools/latex/)
3. [Xournal++ toolbar colors and GPL palettes](https://xournalpp.github.io/guide/config/toolbar-colors/)
