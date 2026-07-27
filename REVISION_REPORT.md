# Relatório de Revisão de Sintaxe: NixOS Unstable vs 24.05

Este documento detalha as mudanças de sintaxe e estrutura realizadas para garantir a compatibilidade total do repositório com o canal estável **NixOS 24.05**.

| Componente | Mudança na Sintaxe / Estrutura | Motivo da Alteração |
| :--- | :--- | :--- |
| **Hardware Graphics** | `hardware.graphics` → `hardware.opengl` | No 24.05, o renomeio para `graphics` ainda não havia ocorrido; a opção correta é `opengl`. |
| **NVIDIA 32-bit** | `driSupport32bit` → `driSupport32Bit` | Correção de "CamelCase": o 'B' deve ser maiúsculo para ser reconhecido pela opção oficial. |
| **NVIDIA Options** | Remoção de `enable32Bit` | Esta opção não existe dentro do bloco `hardware.opengl` no 24.05; o suporte é herdado de `driSupport32Bit`. |
| **Niri Wrapper** | Injeção de `pkgs.xorg.lndir` | O wrapper do Niri falhava ao não encontrar `lndir` no topo do `pkgs`. Ele foi injetado manualmente. |
| **Niri Config** | Remoção de `v2-settings` | A versão estável do wrapper disponível via flake não suporta as configurações da V2 do Niri. |
| **Noctalia Wrapper** | Injeção de `noctalia-shell` | O pacote não existe no nixpkgs oficial; foi buscado diretamente do input `wrapper-modules`. |
| **XWayland Satellite** | Remoção do pacote | `xwayland-satellite` é muito recente e não está presente no canal 24.05. |
| **Home Manager** | Remoção de `home.activation` | Scripts de ativação para criação de pastas podem causar falhas de permissão no build; pasta `~/Projects` deve ser criada manualmente. |
| **Neovim Config** | `extraConfig` → `extraLuaConfig` | Evita o uso de blocos `lua << EOF` e problemas de escape de caracteres, tornando a config 100% Lua. |

## Observações Importantes
- O canal **26.05** mencionado anteriormente **não existe**; as versões seguem o padrão `YY.05` e `YY.11`.
- Todos os wrappers (Niri e Noctalia) foram simplificados para usar a injeção de dependências mínima necessária, garantindo que o build não seja interrompido por atributos ausentes no `pkgs`.
