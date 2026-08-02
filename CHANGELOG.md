# Changelog

## [Não publicado] Shell migration: Ambxst → DankMaterialShell

O shell **Ambxst-X** foi substituído pelo **DankMaterialShell** (DMS). A integração
anterior (axctl, settings/*.json, systemd unit customizado) foi removida; o DMS é
consumido via o flake `shell-conf` reescrito, que re-exporta os módulos HM e NixOS
oficiais do upstream (`github:AvengeMedia/DankMaterialShell`).

**Removido:**
- `modules/features/ambxst.nix`
- `scripts/sync-ambxst-presets.sh`, `scripts/sync-shell-conf-assets.sh`
- Todas as referências a `ambxst`, `axctl`, `Ambxst-X` em `*.nix` e docs

**Adicionado:**
- `modules/features/dank-material-shell.nix` — importa shell-conf DMS modules,
  preserva pipewire/bluetooth/keyring/system packages do antigo ambxst module
- Todas as keybinds em `hyprland.nix` agora usam `dms ipc call ...`
- Corrigido caminho da sessão Hyprland (UWSM) para `share/wayland-sessions/` para compatibilidade com SDDM.

**Alterado:**
- `modules/hosts/*/configuration.nix`: `self.nixosModules.ambxst` → `self.nixosModules.dankMaterialShell`
- `home/livara/home.nix`: comentários Ambxst removidos
- `flake.nix`: input comment atualizado para DMS
- `modules/README.md`: Ambxst → DankMaterialShell na tabela de features

**Nota:** A sessão Hyprland (UWSM) permanece inalterada. O DMS é iniciado pelo
systemd user service `dms.service` vinculado a `graphical-session.target`.

**Para ativar:** `sudo nixos-rebuild switch --flake .#myMachine`

---

## [Não publicado] Correção integrada Hyprland Lua, Ambxst-X e SilentSDDM

### Correções de inicialização e integração
- **Hyprland**: Migração da configuração Home Manager de Hyprlang para a API Lua do Hyprland 0.55+, eliminando `$mod`, `windowrulev2`, `bindl` e `bindel` de um arquivo `hyprland.lua`.
- **Ambxst-X**: Troca da linha legada `source = .../hyprland.conf` por carregamento Lua protegido de `~/.local/share/ambxst/hyprland.lua`, com bootstrap idempotente para o primeiro login.
- **Dependências**: O módulo NixOS oficial do Ambxst-X passou a ser reexportado pelo `shell-conf`, evitando aliases de pacote incorretos e dependências runtime omitidas. O WirePlumber foi habilitado explicitamente, fornecendo o `wpctl` usado pelos binds de áudio.
- **Configuração do shell**: Adicionados `weather.json` e `prefix.json`; removido o `info.json` sem consumidor; `binds.json` deixou de ser um link imutável para que o Ambxst-X possa mantê-lo e migrá-lo.

### Login, avatar e portais
- **SDDM**: Tema Pixie substituído pelo módulo oficial do SilentSDDM, mantendo o wallpaper anterior.
- **Avatar**: `programs.silentSDDM.profileIcons.livara` e `~/.face.icon` agora usam o mesmo ativo versionado, sincronizando greeter e shell por uma única fonte de verdade.
- **Portais**: XDPH passou a ser o backend prioritário para a sessão Hyprland; GTK permanece apenas como fallback de file chooser.
- **Artefatos**: Removido o link `result` quebrado, que apontava para uma derivação Noctalia obsoleta, e adicionadas regras de ignorados para resultados locais do Nix.

---

## [2026-07-30] Migração para Hyprland + Ambxst-X

### Alterações Principais
- **Compositor**: Migração completa do Niri para o Hyprland.
- **Shell**: Substituição do Noctalia pelo Ambxst-X (vendored via `shell-conf`).
- **Login Manager**: Substituição do tema Noctalia pelo tema Astronaut no SDDM.
- **Arquitetura**: Remoção de módulos legados e simplificação de inputs do flake.

### Detalhes Técnicos
- Adicionado módulo `hyprland.nix` com suporte a **UWSM**.
- Atualizado `ambxst.nix` para integrar com Hyprland via `axctl`.
- Removido `niri.nix`, `shell.nix` e diretório `modules/archive/`.
- Removidos inputs `nixpkgs-stable` e `wrapper-modules` do `flake.nix`.
- Mapeadas configurações JSON do usuário para `~/.config/ambxst/config/`.

---

## Refatoração de organização e modularidade

### Estrutura
- `ARCHITECTURE.md` atualizado para refletir a arquitetura atual.
- `ARCHITECTURE_REVIEW_REPORT.md` reescrito com as revisões arquiteturais aplicadas até agora.
- Módulo `system-hardening` ativado no `configuration.nix`.

### Auditoria de segurança e hardening
- Política padrão `DROP` configurada explicitamente.
- mDNS (UDP 5353) permitido.
- Hardening do kernel e desativação de redirecionamentos ICMP.
- Journald configurado com limites de armazenamento e retenção.

---

## Correção do erro de compilação (attribute 'nixvim' missing)

### Home Manager
- Desktop entry do Neovim corrigido para referenciar o pacote do flake `vim-conf`.
- Parâmetro `lib` adicionado ao escopo de `home.nix`.

---

## Migração para nixos-unstable

### Gráficos
- `hardware.opengl` -> `hardware.graphics` (sintaxe moderna do NixOS).
- `driSupport32Bit` -> `enable32Bit` dentro de `hardware.graphics`.

### NVIDIA
- Driver `legacy_580` para GPUs Pascal.

### Home Manager
- `stateVersion` atualizado para `26.11`.
