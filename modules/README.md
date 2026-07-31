# Módulos do sistema

Este diretório concentra os módulos que compõem as configurações NixOS do repositório. A documentação de arquitetura, aplicação e validação está disponível no [README da raiz](../README.md).

| Diretório | Responsabilidade |
|---|---|
| `features/` | Funcionalidades reutilizáveis de sistema, como greeter, compositor, drivers, firewall, Ambxst, Hyprland e portais. |
| `packages/` | Declaração de pacotes Nix e Flatpak. |
| `hosts/` | Configurações específicas de máquina, incluindo hardware, locale e preferências locais. |
| `parts.nix` | Definição dos sistemas suportados e composição dos módulos de flake. |

Cada feature expõe um módulo em `flake.nixosModules.<nome>` ou `flake.homeManagerModules.<nome>`, conforme o nível em que suas opções devem ser avaliadas. Os hosts importam apenas os módulos necessários e preservam os detalhes de hardware em seus próprios diretórios.

## Novo host

Para adicionar um host, crie `modules/hosts/<host>/configuration.nix`, `default.nix` e `hardware.nix`. O `configuration.nix` deve importar as features desejadas; o `default.nix` deve declarar a configuração NixOS com o nome do novo host; e o `hardware.nix` deve conter os módulos e UUIDs específicos da máquina. Quando o desktop usar widgets por monitor, inclua também `desktop-widgets.json` no diretório do host.

Depois, registre o host em `flake.nix` sob `nixosConfigurations` e valide a derivação correspondente antes de aplicar a configuração:

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

## Nova feature

Uma feature deve ter uma única responsabilidade e expor um módulo NixOS ou Home Manager com nome estável. Mantenha opções de hardware e identidade de host fora de `features/`; mantenha pacotes específicos em `packages/`; e documente qualquer dependência entre módulos no cabeçalho do arquivo ou no README da raiz.
