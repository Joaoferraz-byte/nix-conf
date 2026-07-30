# Relatório de Revisão Arquitetural — nix-conf

## Status da Migração (2026-07-30)

A migração de Niri/Noctalia para Hyprland/Ambxst-X foi concluída. Este relatório resume as principais mudanças aplicadas para garantir uma arquitetura limpa, modular e moderna.

### 1. Transição de Compositor (Niri → Hyprland)
O compositor Niri foi substituído pelo Hyprland. A integração agora utiliza o **UWSM** (Universal Wayland Session Manager) no módulo NixOS, garantindo que as variáveis de ambiente e a sessão do systemd sejam gerenciadas corretamente.

### 2. Tema do Greeter (Astronaut)
O tema Noctalia do SDDM foi substituído pelo tema **Astronaut**. Esta mudança alinha o login manager com a estética moderna do Ambxst-X e remove a dependência de módulos de tema legados.

### 3. Integração Ambxst-X
O shell Ambxst-X agora é consumido diretamente como um **flake input** no repositório `shell-conf`. Isso simplifica a manutenção e permite atualizações upstream contínuas. As configurações JSON do usuário foram preservadas e mapeadas para o novo caminho de configuração.

### 4. Limpeza de Remanescentes
Todos os módulos legados (`niri.nix`, `shell.nix`, `noctalia.nix`, `noctalia.json`) foram removidos. O pino de `nixpkgs-stable` que era necessário para o Niri também foi eliminado, simplificando o `flake.nix` principal.

### 5. Padronização de Hosts
As configurações dos hosts (`my-machine` e `dell-latitude-5410`) foram atualizadas para importar o novo módulo `hyprland` e remover referências ao Niri.

## Próximos Passos Recomendados

- **Consolidação de Pacotes**: Criar um módulo centralizado para gerenciar pacotes de desenvolvimento (Java/C++) e evitar duplicatas entre o sistema e o Neovim.
- **Automação de Wallpapers**: Implementar um script para sincronizar a coleção local de wallpapers com o seletor do Ambxst-X.
- **Persistência de Widgets**: Salvar as configurações de widgets feitas via interface do Ambxst-X de volta no `shell-conf/settings/`.
