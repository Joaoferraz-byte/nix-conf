# Decisão de integração Ambxst — NixOS e Home Manager

**Decisão registrada em:** 2 de agosto de 2026
**Configuração auditada:** `nix-conf` em `18a641f6e4760f3af27e129f79bbc2ea11748326`; `shell-conf` atualizado como input para `01af79ed110979b523236b46ec315d8922112195`.

> **Decisão:** manter o Ambxst-X vendorizado pelo `shell-conf` e preservar a separação atual entre a configuração declarativa do Hyprland e o estado mutável controlado pela interface. Não integrar agora a PR #196 nem trocar a fonte pelo Ambxst principal.

## Razão arquitetural

O Ambxst principal já disponibiliza um pacote Nix e um módulo NixOS, mas a auditoria não identificou uma camada Home Manager estável que inicialize, migre e preserve o estado mutável de Ambxst. A documentação oficial do Hyprland estabelece a configuração por Home Manager como uma fronteira declarativa própria; ela não substitui automaticamente a persistência de preferências de uma aplicação de interface.[1] [2]

A PR #196 do upstream, que contém o sincronizador de configuração Hyprland considerado na análise, permanece aberta e não mesclável. Ela usa caminhos legados em `~/.config/ambxst`, gera arquivos auxiliares em `~/.local/share/ambxst` e não abrange presets de temas, cores ou preferências de aplicativos. Isso diverge do contrato atual, que mantém o estado editável do usuário sob `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst`.[3]

Por essa razão, o módulo `ambxst.nix` continua sendo responsável pela integração de sessão e pela fronteira de estado atual, enquanto o módulo declarativo de Hyprland mantém sua autoridade sobre as opções que pertencem a NixOS/Home Manager. Nenhuma mudança deste ciclo altera arredondamento, binds, Super+Return, perfis de teclado, temas ou presets.

## Correção de reprodutibilidade aplicada

A avaliação inicial de `nix flake check --no-build` falhou antes de alcançar a avaliação completa das configurações NixOS porque o pin remoto de `shell-conf` no `flake.lock` apresentava divergência de NAR hash. O lockfile foi atualizado de `9c20713db625c46d60422da9bd9f3440c4cbeb92` para a revisão atual e validada `01af79ed110979b523236b46ec315d8922112195`.

| Aspecto | Pin anterior | Pin corrigido |
|---|---|---|
| Revisão de `shell-conf` | `9c20713db625c46d60422da9bd9f3440c4cbeb92` | `01af79ed110979b523236b46ec315d8922112195` |
| NAR hash | `sha256-2aI3zF35sWh1hwgCINnOdtfTllvwRjQIpIebAYlM/qM=` | `sha256-7uJvbh914JA5qcPF5eNOM+CQdpGXIPzgZrNZJoPgv7I=` |
| Resultado esperado | Falha de integridade durante a avaliação | Avaliação reprodutível contra a fonte atual |

A atualização é propositalmente restrita ao input que falhava. Nenhum outro input da flake foi atualizado neste ciclo, preservando a superfície de mudança e facilitando a atribuição de qualquer resultado de validação posterior.

## Condições para uma futura troca de fonte

A migração para o Ambxst principal somente deve ser reaberta quando existir uma implementação estável de sincronização equivalente, uma migração explícita do estado em XDG, um contrato de bootstrap e propriedade de arquivos compatível com Home Manager, e testes que cubram geração/reload do Hyprland, `axctl`, arredondamento, atalhos, temas e presets. A decisão final deve ser acompanhada por `nix flake check` nas flakes de `shell-conf` e `nix-conf` e por teste manual numa sessão Hyprland do host alvo.

## Referências

[1]: https://github.com/Axenide/Ambxst "Axenide/Ambxst"
[2]: https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/ "Hyprland on Home Manager"
[3]: https://github.com/Axenide/Ambxst/pull/196 "PR #196 — Merge NothingLess improvements into Ambxst"
[4]: https://github.com/Joaoferraz-byte/shell-conf "Joaoferraz-byte/shell-conf"
