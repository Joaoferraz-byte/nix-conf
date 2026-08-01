# Correção de Atalhos e Arredondamento (Rounding)

Este documento detalha as correções aplicadas para restaurar a funcionalidade dos atalhos de workspace, o atalho `Super+T` e o arredondamento das janelas.

## Problema Identificado

Os atalhos de workspace (Super+1-0) e o arredondamento das janelas não estavam funcionando porque dependiam inteiramente do daemon `axctl` do Ambxst-X. Se o daemon falhasse ao iniciar ou o socket IPC não estivesse pronto, o Hyprland ficava sem essas configurações essenciais. Além disso, o atalho `Super+T` (Tmux) não estava definido nativamente.

## Causa Raiz

1. **Ausência de Binds Nativos**: O arquivo `hyprland.nix` definia apenas atalhos de recuperação (`Super+Return`, `Super+R`, `Super+Shift+Q`).
2. **Dependência Dinâmica**: O arredondamento (rounding) era aplicado dinamicamente pelo shell via `hyprctl`, sem um valor padrão definido na configuração principal do compositor.
3. **Paridade com Ambxst**: O Ambxst original utiliza `Super+T` para abrir o gerenciador de tmux, enquanto o usuário estava usando atalhos de terminal puro.

## Soluções Implementadas

### 1. Binds Nativos no Hyprland (Lua)
Adicionamos atalhos nativos diretamente no `modules/features/hyprland.nix` usando a sintaxe Lua do compositor. Isso garante que a navegação básica funcione mesmo que o shell falhe.
- **Workspaces**: Adicionados binds para `Super + [1-9, 0]` e `Super + Shift + [1-9, 0]`.
- **Terminal Tmux**: Adicionado bind para `Super + T` executando `ambxst run tmux`.

### 2. Decoração Padrão (Rounding)
Definimos valores padrão de decoração no bloco `hl.config` do `hyprland.nix`:
- `rounding = 16` (valor padrão do Ambxst).
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

Com essas mudanças, o arredondamento será aplicado imediatamente ao iniciar o Hyprland, e os atalhos de workspace estarão sempre disponíveis.
