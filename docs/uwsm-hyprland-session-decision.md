# Nota técnica: sessão Hyprland/UWSM e `XDG_CURRENT_DESKTOP`

## Achados externos preservados

A revisão de `nixpkgs` fixada neste repositório é `624af665418d3c65d544145b4d34ad696439570e`. Nela, `programs.hyprland.withUWSM = true` apenas habilita `programs.uwsm`; o módulo UWSM gera desktop entries que chamam `uwsm start -F -- <binPath>`. O gerador padrão não oferece, nessa forma, uma opção para preencher explicitamente o nome de desktop da sessão.

O manual do UWSM documenta que `uwsm start -D <nomes>` define `XDG_CURRENT_DESKTOP` e que `-e` torna esses nomes exclusivos, descartando fontes externas. Portanto, `uwsm start -F -eD Hyprland -- <comando>` é a forma explícita de preservar a identidade de desktop esperada pelo Hyprland.[1]

A issue NixOS/nixpkgs #476375 descreve exatamente o efeito observado: a sessão iniciada pelo desktop entry UWSM recebe `XDG_CURRENT_DESKTOP=start-hyprland`, e o workaround registrado é `uwsm start -eD Hyprland hyprland.desktop`.[2] A discussão Hyprland #12661 confirma que o alerta é relacionado ao caminho de inicialização e às variáveis de ambiente, e não deve ser apenas ocultado com `disable_watchdog_warning`.[3]

## Decisão de integração

O módulo local deve continuar a usar UWSM e desabilitar a integração systemd do Home Manager, como recomendado pela documentação do Hyprland para evitar conflito de dois gerenciadores de sessão.[4] Em vez de aceitar o desktop entry automático, ele declarará **uma única sessão UWSM própria** que:

1. executa `/run/current-system/sw/bin/start-hyprland`, preservando a inicialização suportada pelo próprio Hyprland;
2. invoca UWSM com `-F -eD Hyprland`, definindo `XDG_CURRENT_DESKTOP=Hyprland` de forma determinística;
3. declara `DesktopNames=Hyprland` para que portais e consumidores XDG reconheçam a sessão;
4. substitui a sessão automática `hyprland-uwsm` em vez de adicionar duas opções concorrentes ao display manager;
5. inicia Ambxst como serviço de usuário associado a `graphical-session.target`, não via gancho Lua do compositor.

## Referências

[1]: https://man.archlinux.org/man/uwsm.1.en "UWSM(1) — opções `start`, `-D` e `-e`"
[2]: https://github.com/NixOS/nixpkgs/issues/476375 "NixOS/nixpkgs #476375 — XDG_CURRENT_DESKTOP incorreto com UWSM"
[3]: https://github.com/hyprwm/Hyprland/discussions/12661 "Hyprland discussion #12661 — inicialização via UWSM e start-hyprland"
[4]: https://wiki.hypr.land/Useful-Utilities/Systemd-start/ "Hyprland Wiki — UWSM e Home Manager"
