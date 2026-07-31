# nix-conf

## Visão geral

Este repositório contém a configuração NixOS modular dos hosts `myMachine` e `dellLatitude5410`. Ele organiza opções de sistema, hardware, desktop, pacotes e Home Manager em módulos independentes, com uma integração declarativa do Ambxst para Hyprland.

| Área | Localização | Responsabilidade |
|---|---|---|
| Flake e entradas fixadas | `flake.nix`, `flake.lock` | Define os hosts e fixa todas as dependências transitivas. |
| Hosts | `modules/hosts/` | Declara hardware, nome do host e escolhas específicas de cada máquina. |
| Funcionalidades do sistema | `modules/features/` | Encapsula desktop, Hyprland, portais, áudio, Ambxst e demais serviços. |
| Pacotes | `modules/packages/` | Declara pacotes Nix e Flatpak. |
| Ambxst | `modules/features/ambxst.nix` | Importa o pacote e os módulos da flake `shell-conf`. |
| Hyprland | `modules/features/hyprland.nix` | Define a sessão UWSM, dispositivos, regras base e recuperação mínima. |

## Arquitetura do desktop

A integração separa deliberadamente componentes estáticos do sistema e componentes dinâmicos do shell.

| Camada | Autoridade | Responsabilidade |
|---|---|---|
| NixOS e Home Manager | `nix-conf` | Sessão Hyprland, UWSM, portais, serviços, pacotes, cursor, teclado e recuperação. |
| Shell gráfico | `shell-conf` | Fonte vendorizada do Ambxst, defaults de primeira inicialização e módulo Home Manager. |
| Runtime mutável | Ambxst | Tema, painel, presets e configurações editadas pela interface em `XDG_STATE_HOME/ambxst`. |
| Aplicação dinâmica | `axctl` | Regras de compositor e atalhos do Ambxst via IPC do Hyprland. |

O módulo `ambxst.nix` importa `inputs.shell-conf.nixosModules.default`, ativa `programs.ambxst` e entrega `inputs.shell-conf.homeManagerModules.default` a todos os perfis Home Manager. Assim, a configuração mutável é preparada uma vez por usuário e o pacote Ambxst consumido pelo sistema é o construído a partir da fonte auditada no `shell-conf`.

## Hyprland e Ambxst

O Hyprland utiliza `configType = "lua"`. Nessa modalidade, `settings.exec_once` não é uma API válida; o início do Ambxst é registrado no evento `hyprland.start`, que é executado uma vez por sessão. A configuração não carrega o Lua gerado em uma sessão anterior pelo `axctl`, pois o daemon aplica o estado atual diretamente por IPC. Isso evita que autostarts e atalhos obsoletos sejam reaplicados no primeiro boot. [1] [2]

O UWSM recebe o binário real `Hyprland` e a variável `XDG_CURRENT_DESKTOP` é normalizada para `Hyprland`. Essa dupla proteção impede que wrappers de sessão sejam propagados como identidade de desktop para o Ambxst e outros componentes Wayland.

| Atalho | Função | Motivo |
|---|---|---|
| `SUPER + T` | Interface de gerenciamento de terminais/tmux do Ambxst. | É reservado ao shell e não é redefinido pelo NixOS. |
| `SUPER + Return` | Abre `kitty`. | Caminho de recuperação independente do Ambxst. |
| `SUPER + R` | Executa `ambxst reload`. | Recuperação para recarregar o shell. |
| `SUPER + SHIFT + Q` | Executa `uwsm stop`. | Recuperação para encerrar a sessão. |

Os atalhos dinâmicos pertencem ao Ambxst e ao `axctl`; os três últimos são os únicos atalhos mantidos pelo módulo Hyprland. Esta divisão impede colisões com `SUPER + T` e reduz a concorrência entre arquivos de configuração.

## Aplicação da configuração

Execute os comandos a partir da raiz deste repositório. Escolha o host que corresponde à máquina de destino.

```bash
sudo nixos-rebuild switch --flake .#myMachine
# ou
sudo nixos-rebuild switch --flake .#dellLatitude5410
```

Para apenas construir a configuração antes de aplicar mudanças:

```bash
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
nix build .#nixosConfigurations.dellLatitude5410.config.system.build.toplevel
```

Os comandos abaixo verificam a estrutura da flake e a resolução das dependências sem executar uma troca de geração:

```bash
nix flake check --no-build
nix build --dry-run --no-link .#nixosConfigurations.myMachine.config.system.build.toplevel
nix build --dry-run --no-link .#nixosConfigurations.dellLatitude5410.config.system.build.toplevel
```

> O aviso `unknown flake output 'homeManagerModules'` produzido por algumas versões de `nix flake check` é informativo. `homeManagerModules` é uma extensão de convenção para módulos Home Manager e o verificador de flakes não valida extensões de terceiros por nome. [3] [4]

## Atualizações

Atualize entradas de forma intencional e valide ambos os hosts antes de aplicar uma nova geração:

```bash
nix flake lock --update-input shell-conf
nix flake check --no-build
nix build --dry-run --no-link .#nixosConfigurations.myMachine.config.system.build.toplevel
```

Atualizações do Ambxst devem ser feitas primeiro no `shell-conf`, onde a fonte completa está vendorizada e as alterações em QML, launcher, `axctl` e módulo Nix podem ser revisadas conjuntamente. Depois da publicação da revisão do `shell-conf`, atualize o input neste repositório e reavalie os hosts.

## Referências

[1]: https://wiki.hypr.land/Configuring/Using-Lua/ "Hyprland: Using Lua"
[2]: https://wiki.hypr.land/Configuring/Start/ "Hyprland: Start"
[3]: https://discourse.nixos.org/t/custom-flake-outputs-for-checks/18877 "Custom flake outputs for checks"
[4]: https://discourse.nixos.org/t/nixos-home-manager-config-where-both-use-flakes/41410 "NixOS + Home Manager config where both use flakes"
[5]: https://github.com/Joaoferraz-byte/shell-conf "shell-conf"
[6]: https://github.com/Axenide/axctl "axctl"
