# Módulos do Sistema

Este diretório contém todos os módulos NixOS do repositório, organizados em três camadas:

## Estrutura

| Diretório | Responsabilidade |
| :--- | :--- |
| `features/` | Funcionalidades do sistema (greeter, compositor, drivers, firewall, etc.) |
| `packages/` | Gerência declarativa de pacotes (Nix e Flatpak) |
| `hosts/` | Configuração específica de cada máquina (hardware, locale, usuário) |

## Convenções

- Cada módulo em `features/` exporta `flake.nixosModules.<nome>` para ser importado pela configuração do host.
- Cada host em `hosts/<nome>/` contém: `configuration.nix` (importa módulos), `default.nix` (define `nixosConfiguration`), `hardware.nix` (gerado pelo `nixos-generate-config`), e arquivos host-specific como `desktop-widgets.json`.
- O `parts.nix` na raiz de `modules/` define os sistemas suportados (`x86_64-linux`, `aarch64-linux`).

## Adicionando um Novo Host

1. Crie `modules/hosts/<host>/configuration.nix` copiando o `my-machine/configuration.nix` como base.
2. Crie `modules/hosts/<host>/default.nix` copiando o `my-machine/default.nix` e ajustando o nome.
3. Crie `modules/hosts/<host>/hardware.nix` com os UUIDs e módulos específicos da máquina.
4. Crie `modules/hosts/<host>/desktop-widgets.json` com o layout de widgets do Noctalia para o monitor dessa máquina.
5. Adicione o novo host ao `flake.nix` sob `nixosConfigurations`.

## Adicionando um Novo Módulo de Feature

1. Crie `modules/features/<nome>.nix` com a estrutura padrão:
   ```nix
   { ... }: {
     flake.nixosModules.<nome> = { pkgs, lib, ... }: {
       # configuração
     };
   }
   ```
2. Importe-o no `configuration.nix` do host que precisa dessa feature.
