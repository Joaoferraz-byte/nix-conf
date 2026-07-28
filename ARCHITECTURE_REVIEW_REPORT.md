# Relatório de Revisão de Arquitetura — nix-conf

## Visão Geral

Este relatório documenta a revisão arquitetural e a refatoração do repositório `nix-conf`, uma configuração baseada em NixOS flake para um desktop NVIDIA apenas Linux usando o compositor Niri Wayland com Home Manager.

---

## Melhorias Arquiteturais

### 1. Eliminação de configuração redundante e depreciada do Niri

**Arquivo:** `modules/features/niri.nix`

A opção `v2-settings = true` no wrapper niri do nix-wrapper-modules foi removida, pois agora é o comportamento padrão. O `overrideAttrs` que definia manualmente `providedSessions = [ "niri" ]` também foi removido, pois o módulo wrapper agora passa o `providedSessions` automaticamente. O blur de fundo foi mantido, pois é válido desde o Niri 26.04.

### 2. Restauração da correção do ícone da bandeja do AudioRelay

**Arquivo:** `modules/features/audiorelay.nix`

As variáveis de ambiente `XDG_CURRENT_DESKTOP = "GNOME"` e `DBUS_SESSION_BUS_ADDRESS` foram restauradas para os overrides do Flatpak do AudioRelay. Isso força o protocolo StatusNotifierItem, permitindo que o ícone da bandeja renderize corretamente sob o Noctalia. A utilização de `$XDG_RUNTIME_DIR` torna a configuração mais robusta.

### 3. Consolidação do RTKit com PipeWire

**Arquivo:** `modules/features/audiorelay.nix`, `modules/features/desktop-portals.nix`

`security.rtkit.enable = true` foi movido para `audiorelay.nix`, onde o PipeWire é ativado. O RTKit é funcionalmente acoplado ao PipeWire para permitir escalonamento em tempo real, e sua presença no módulo de portais era uma violação de separação de responsabilidades.

### 4. Correção do caminho JAVA_HOME

**Arquivo:** `home/livara/neovim.nix`

`JAVA_HOME` foi corrigido para `"${pkgs.jdk21}/lib/openjdk"`. O valor anterior apontava para a raiz do pacote, mas o diretório home real do JDK em NixOS fica em `$out/lib/openjdk`. Isso corrige falhas em ferramentas como `jdt-language-server` e `Spring Boot CLI`.

### 5. Remoção de configurações duplicadas, correção de licença NVIDIA e ativação do Home Manager

**Arquivos:** `modules/hosts/my-machine/configuration.nix`, `modules/hosts/my-machine/default.nix`

- A importação duplicada do módulo `home-manager` foi removida do `configuration.nix`.
- O erro de licença NVIDIA foi resolvido adicionando `nixpkgs.config.allowUnfree = true` diretamente na definição do `nixosSystem` no `default.nix`, garantindo que a avaliação do sistema permita drivers proprietários.
- O conflito de ativação do Home Manager foi resolvido adicionando `home-manager.backupFileExtension = "backup"` no `default.nix`, permitindo que o sistema faça backup de arquivos existentes (como `mimeapps.list`) em vez de falhar.
- `system.stateVersion` e `home.stateVersion` foram atualizados para `26.11` conforme detectado na versão instável do sistema para garantir compatibilidade total.

### 6. Ativação do módulo Keyd

**Arquivo:** `modules/hosts/my-machine/configuration.nix`

O módulo `keyd.nix`, que estava definido mas inativo, foi finalmente importado na configuração do host, ativando o remapeamento de teclado desejado (`leftmeta` como `overload(meta, menu)`).

---

## Arquivos Modificados

| Arquivo | Alteração |
| :--- | :--- |
| `modules/features/niri.nix` | Removido `v2-settings` depreciado, removido `providedSessions` redundante, traduzido comentários. |
| `modules/features/audiorelay.nix` | Restaurado variáveis de ambiente da bandeja, movido `rtkit`, traduzido comentários. |
| `modules/features/desktop-portals.nix` | Removido `rtkit`, traduzido comentários. |
| `modules/hosts/my-machine/configuration.nix` | Ativado módulo `keyd`, atualizado `stateVersion`, removido duplicatas. |
| `modules/hosts/my-machine/default.nix` | Corrigido erro NVIDIA e adicionado `backupFileExtension` para o Home Manager. |
| `home/livara/home.nix` | Atualizado `stateVersion` para `26.11` e traduzido descrições. |
| `home/livara/neovim.nix` | Corrigido `JAVA_HOME`, traduzido comentários e descrições de teclas. |
| `CHANGELOG.md` | Traduzido para português e atualizado com as novas correções. |
| `ARCHITECTURE_REVIEW_REPORT.md` | Traduzido e atualizado com o estado final da revisão técnica. |

---

## Dívidas Técnicas Restantes

1. **Pino de nixpkgs-stable para o Niri**: Ainda necessário devido a falhas transientes na `libdisplay-info` no canal unstable. Deve ser removido quando corrigido upstream.
2. **Ausência de CI/CD**: O repositório ainda não possui automação para validar o flake via GitHub Actions.
3. **Configuração do Neovim Monolítica**: O arquivo `neovim.nix` é extenso e poderia ser modularizado em arquivos separados para LSP, plugins e keymaps.
