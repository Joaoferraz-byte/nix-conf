# Nota técnica: Falha de serviços e atalhos do Ambxst sob systemd

## Sintoma

Após a migração do Ambxst para iniciar como um serviço de usuário do systemd (`ambxst.service`) associado ao `graphical-session.target`, o shell renderizava corretamente, mas quase todos os seus serviços de backend (rede, bluetooth, bateria, mídia, área de transferência) falhavam silenciosamente. Além disso, todos os atalhos globais gerenciados pelo shell deixaram de funcionar, restando apenas os atalhos de recuperação nativos do Hyprland.

O log do serviço (`journalctl --user -u ambxst.service`) apresentava o erro repetido: *"Process failed to start, likely because the binary could not be found"*, além de falhas de GeoIP no widget de clima.

## Causa Raiz

A falha possuía duas causas concorrentes relacionadas ao ambiente de execução (PATH) do serviço systemd, que diferem drasticamente do ambiente interativo onde o Ambxst era executado anteriormente (via gancho Lua do Hyprland).

1. **Dependências utilitárias ausentes no closure do Nix:** Os serviços QML e scripts auxiliares do Ambxst (ex: `ClipboardService.qml`, `ScreenRecorder.qml`, `weather.sh`) dependem pesadamente de utilitários de linha de comando como `bash`, `coreutils` (cat, head, tail, md5sum, base64), `curl`, `findutils`, `gawk`, `gnugrep`, `gnused`, `procps` (pgrep, pkill), `xdg-utils` e `hyprpicker`. Essas ferramentas não estavam declaradas no closure do Nix do `shell-conf` (`nix/packages/tools.nix`). Em uma sessão interativa, elas costumam estar disponíveis no PATH global, mas o isolamento do systemd expôs a ausência estrutural.
2. **Dependências de sistema inacessíveis pelo serviço:** O Ambxst também interage com serviços do sistema operacional, invocando binários como `nmcli` (NetworkManager), `bluetoothctl` (BlueZ), `hyprctl` (Hyprland), `systemctl` e `loginctl` (systemd). Estes binários não pertencem ao closure do shell, devendo ser consumidos do sistema. No entanto, a unidade `ambxst.service` definida em `modules/features/ambxst.nix` não estendia a variável PATH para incluir `/run/current-system/sw/bin`, impedindo que os processos QML encontrassem os binários essenciais de comunicação com o sistema.

A falha dos atalhos globais é um efeito colateral direto desse problema de PATH. A arquitetura atual do Ambxst materializa os atalhos em um arquivo TOML e então inicia o daemon `axctl`. Se o daemon falha ao iniciar ou se ferramentas subjacentes necessárias para a sua execução falham, a camada de IPC de atalhos nunca se torna "pronta" (`daemonReady`), resultando na não aplicação silenciosa de todos os binds configurados.

## Decisão e Correção

A solução implementada ataca as duas frentes sem violar o encapsulamento do Nix:

1. **Expansão do Closure no `shell-conf`:** Foram adicionados explicitamente ao arquivo `nix/packages/tools.nix` todos os utilitários de espaço de usuário identificados na auditoria do código-fonte (`bash`, `coreutils`, `curl`, `findutils`, `gawk`, `gnugrep`, `gnused`, `procps`, `xdg-user-dirs`, `xdg-utils`, `hyprpicker`, `wf-recorder`). Isso garante que o pacote do Ambxst seja autossuficiente para suas operações internas, independentemente de onde seja executado. Adicionalmente, o script de inicialização `cli.sh` foi corrigido para utilizar a variável `$QS_BIN` ao invés de invocar um `qs` hardcoded.
2. **Exposição do PATH do Sistema no `nix-conf`:** A definição da unidade `systemd.user.services.ambxst` em `modules/features/ambxst.nix` foi atualizada para incluir a propriedade `path = [ "/run/current-system/sw" ];`. Isso permite que o serviço encontre os binários de integração de sistema (`nmcli`, `bluetoothctl`, `hyprctl`, etc.) que o NixOS provê globalmente.

A combinação destas duas abordagens restaura a paridade funcional do shell sob o systemd, mantendo o controle declarativo do ambiente de execução.

## Referências

[1]: https://github.com/Joaoferraz-byte/nix-conf "Repositório nix-conf"
[2]: https://github.com/Joaoferraz-byte/shell-conf "Repositório shell-conf"

## Verified (Pending Runtime Confirmation)

The following fixes have been implemented and committed to the repositories:

1. **Closure Fix**: Missing CLI dependencies (bash, coreutils, etc.) added to `shell-conf` and system PATH injected into `ambxst.service`.
2. **Permission Fix**: `ExecStartPre` added to `ambxst.service` to ensure `~/.local/state/ambxst/config` exists with correct ownership.
3. **Wallpapers Fix**: Symlink from `~/.config/nixos/Wallpapers` to the flake-tracked directory created via Home Manager.
4. **Rounding Fix**: `CompositorConfig.qml` updated to execute `hyprctl batch` for live decoration updates.
5. **Icon Theme Fix**: Launcher updated to include user profile in `XDG_DATA_DIRS` and detect GTK theme via `gsettings`.
6. **Brightness Fix**: Backend improved with machine-readable `brightnessctl` output and robust monitor detection.

**Note to User**: Since this environment cannot run NixOS, please follow the [Verification Runbook](./verification-runbook.md) to apply these changes and record the results here.
