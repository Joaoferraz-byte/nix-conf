# Correção: Permissões de escrita e diretório Wallpapers ausente

## Sintoma

O serviço `ambxst.service` registrava erros repetidos no `journalctl`:

```
Write of /home/livara/.local/state/ambxst/config/dock.json failed: Permission denied
```

(o mesmo para `bar.json`, `compositor.json`, `notch.json`, `overview.json`, `workspaces.json`, `performance.json`)

Adicionalmente, o seletor de wallpapers falhava com:

```
find: '~/.config/nixos/Wallpapers': No such file or directory
```

## Causa Raiz

### Permissão negada nos arquivos de configuração

A cadeia de resolução de path para os arquivos de configuração do Ambxst é:

1. O launcher (`nix/packages/default.nix` no shell-conf) define `AMBXST_CONFIG_ROOT` como `${XDG_STATE_HOME:-$HOME/.local/state}/ambxst`.
2. `Config.qml` usa `Quickshell.env("AMBXST_CONFIG_ROOT")` para determinar `configRoot`.
3. `configDir = configRoot + "/config"` resulta em `/home/livara/.local/state/ambxst/config`.
4. Os componentes `FileView` escrevem atomicamente em arquivos como `configDir + "/dock.json"`.

O serviço systemd `ambxst.service` não possuía nenhuma diretiva `ExecStartPre` para garantir a existência do diretório de configuração antes de iniciar. Embora o processo `ensureConfigDir` dentro do `Config.qml` execute `mkdir -p` via shell, isso ocorre **depois** que os `FileView` components tentam carregar e salvar seus arquivos. Se o diretório ainda não existir (e.g., primeira execução após rebuild, ou se o diretório foi criado com ownership errado), o `FileView.save()` falha com "Permission denied".

### Diretório Wallpapers ausente

O caminho `~/.config/nixos/Wallpapers` **não é referenciado em nenhum lugar** do código-fonte do shell-conf ou do Ambxst upstream. Ele é um valor de configuração do usuário, persistido em `~/.cache/ambxst/wallpapers.json` como `wallpaperConfig.adapter.wallPath`. O nix-conf armazena wallpapers em `self.outPath + "/Wallpapers"` (rastreado pelo git), mas não havia nenhum symlink ou declaração Home Manager que criasse `~/.config/nixos/Wallpapers`.

## Correção

### 1. ExecStartPre no systemd unit (`modules/features/ambxst.nix`)

Adicionado `ExecStartPre` ao serviço `ambxst` para garantir que o diretório de configuração exista antes da execução:

```nix
serviceConfig = {
  ExecStartPre = [ "-${pkgs.coreutils}/bin/mkdir -p %h/.local/state/ambxst/config" ];
  ...
};
```

### 2. Environment XDG_STATE_HOME no systemd unit

Adicionado `Environment` para garantir que `XDG_STATE_HOME` seja consistente, independentemente da herança de sessão:

```nix
environment = {
  XDG_STATE_HOME = "/home/${config.users.users.livara.name}/.local/state";
};
```

### 3. Symlink para Wallpapers (`home/livara/home.nix`)

Adicionado um symlink declarativo que conecta `~/.config/nixos/Wallpapers` ao diretório de wallpapers versionado no flake:

```nix
home.file.".config/nixos/Wallpapers".source = self.outPath + "/Wallpapers";
```

Isso garante que o caminho configurado pelo usuário no seletor de wallpapers sempre resolva para um diretório válido.

## Notas

- O diretório `~/.local/state/ambxst/config/` é seedado pelo módulo Home Manager do shell-conf (`prepareAmbxstRuntimeState`) durante a ativação, copiando os templates de `settings/`. O `ExecStartPre` é uma garantia adicional para casos em que o serviço inicie antes ou independentemente da ativação do Home Manager.
- O symlink de Wallpapers pode ser substituído no futuro por uma declaração explícita do path em um arquivo JSON de configuração, caso o nix-conf adote uma abordagem totalmente declarativa para a seleção de wallpapers.
