# Restauração de Atalhos e Arredondamento Ambxst

Este documento detalha as correções aplicadas para restaurar a funcionalidade completa dos atalhos e o arredondamento das janelas, garantindo 100% de paridade com o Ambxst original.

## Problema Identificado

Os atalhos (workspaces, launcher, dashboard, etc.) e o arredondamento das janelas dependiam inteiramente do daemon `axctl` do Ambxst-X. Se o daemon falhasse ao iniciar ou o socket IPC não estivesse pronto, o ambiente perdia funcionalidade essencial. Além disso, muitos atalhos do Ambxst original não estavam presentes no fork atual.

## Soluções Implementadas

### 1. Binds Nativos no Hyprland (Lua)
Todos os atalhos foram movidos para a configuração nativa do Hyprland (`modules/features/hyprland.nix`) usando chamadas `hl.bind`. Isso garante que os atalhos funcionem mesmo que o shell falhe.

#### Atalhos Core (Ambxst IPC)
| Tecla | Ação | Comando |
| :--- | :--- | :--- |
| `SUPER` | Launcher | `ambxst run launcher` |
| `SUPER + D` | Dashboard | `ambxst run dashboard` |
| `SUPER + A` | Assistant | `ambxst run assistant` |
| `SUPER + V` | Clipboard | `ambxst run clipboard` |
| `SUPER + .` | Emoji | `ambxst run emoji` |
| `SUPER + N` | Notes | `ambxst run notes` |
| `SUPER + T` | Tmux | `ambxst run tmux` |
| `SUPER + ,` | Wallpapers | `ambxst run wallpapers` |
| `SUPER + SHIFT + C` | Settings | `ambxst run config` |
| `SUPER + TAB` | Overview | `ambxst run overview` |
| `SUPER + ESC` | Power Menu | `ambxst run powermenu` |
| `SUPER + S` | Tools | `ambxst run tools` |
| `SUPER + SHIFT + S` | Screenshot | `ambxst run screenshot` |
| `SUPER + SHIFT + R` | Screen Record | `ambxst run screenrecord` |
| `SUPER + SHIFT + A` | Lens | `ambxst run lens` |
| `SUPER + ALT + B` | Reload Shell | `ambxst reload` |

#### Atalhos de Sistema e Navegação
- `SUPER + C`: Fechar janela ativa.
- `SUPER + F`: Alternar modo flutuante.
- `SUPER + M`: Tela cheia.
- `SUPER + [Setas]`: Mover foco entre janelas.
- `SUPER + SHIFT + [Setas]`: Mover janelas.
- `SUPER + [1-0]`: Mudar de workspace (1-10).
- `SUPER + SHIFT + [1-0]`: Mover janela para workspace.

#### Atalhos de Hardware (Media/Volume/Brightness)
- Mapeamento completo de teclas `XF86` para controle de volume (`wpctl`), brilho (`ambxst brightness`) e mídia (`playerctl`).

### 2. Decoração Padrão (Rounding)
Definimos valores padrão de decoração no bloco `hl.config` do `hyprland.nix`:
- `rounding = 16` (valor padrão do Ambxst).
- `blur = { enabled = true, size = 8, passes = 2 }`.
- `gaps_in = 5` e `gaps_out = 10`.
- Ativação de sombras (`drop_shadow = true`).

## Como Aplicar

1. Atualize seu repositório local:
   ```bash
   cd ~/.config/nixos
   git pull origin main
   ```
2. Reconstrua o sistema:
   ```bash
   sudo nixos-rebuild switch --flake .#myMachine
   ```

Com essas mudanças, o arredondamento será aplicado imediatamente ao iniciar o Hyprland, e a suite completa de atalhos Ambxst estará sempre disponível.
