# Relatório de Modernização: Migração para NixOS Unstable

Este documento detalha a migração do repositório para o canal **nixos-unstable** e a modernização da sintaxe para refletir as mudanças que estarão presentes no futuro NixOS 26.05.

| Componente | Mudança na Sintaxe / Estrutura | Motivo da Alteração |
| :--- | :--- | :--- |
| **Graphics** | `hardware.opengl` → `hardware.graphics` | Sintaxe moderna e padrão no NixOS Unstable. |
| **NVIDIA 32-bit** | `driSupport32Bit` → `enable32Bit` | No unstable, a opção correta dentro de `hardware.graphics` é `enable32Bit`. |
| **LLVM/Clangd** | `clangd` → `llvmPackages.clang-unwrapped` | No unstable, o binário `clangd` é fornecido via pacote de baixo nível do LLVM. |
| **Neovim/XDG Warnings** | Silenciamento de avisos | Ajustadas opções `withRuby`, `withPython3` e `setSessionVariables` para o padrão futuro (26.05). |
| **Niri Config** | Restauração de `v2-settings` | Suporte completo para configurações V2 do Niri no canal unstable. |
| **XWayland Satellite** | Restauração do pacote | Pacote disponível e funcional no nixpkgs unstable. |
| **Nerd Fonts** | `nerdfonts.override` → `nerd-fonts.jetbrains-mono` | Nova forma simplificada de declarar fontes Nerd no unstable. |
| **Wrappers** | Simplificação e Injeção | Wrappers do Niri e Noctalia agora utilizam injeção direta de pacotes do flake para máxima estabilidade. |
| **State Version** | `24.05` → `24.11` | Atualizado para refletir o estado atual do canal unstable. |

## Observações Importantes
- A migração para o **nixos-unstable** permite o uso das versões mais recentes de drivers, compositores e ferramentas de desenvolvimento.
- O Neovim mantém sua configuração como IDE completa, agora com acesso aos plugins e LSPs mais recentes.

