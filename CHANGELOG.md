# Changelog

## Refatoração de organização e modularidade

### Estrutura

- `ARCHITECTURE.md` atualizado para refletir a arquitetura atual (sem referências a `neovim-wrapped` ou `lua-conf`).
- `ARCHITECTURE_REVIEW_REPORT.md` reescrito com as revisões arquiteturais aplicadas até agora.
- `CHANGELOG.md` reescrito removendo referências a módulos e inputs que não existem mais.
- Módulo `system-hardening` agora é importado no `configuration.nix` (estava definido mas inativo).

### Pacotes

- `modules/packages/common.nix` e `modules/packages/flatpak.nix` mantidos sob `packages/` como convenção para gerência de pacotes.
- `modules/features/` reservado para funcionalidades do sistema (greeter, niri, nvidia, etc.).

---

## Auditoria de segurança e hardening

### Firewall

- Política padrão `DROP` configurada explicitamente.
- Porta TCP 1239 (AudioRelay) permitida.
- mDNS (UDP 5353) permitido para Noctalia/Avahi.
- Stateful connection tracking habilitado.

### Kernel

- `ptrace_scope=2`, SYN cookies, source routing desabilitado.
- ICMP redirects desabilitados, IP forwarding desabilitado.
- BPF JIT hardened, kernel pointers ocultos.
- ASLR forçado (`randomize_va_space=2`).

### Boot

- Editor do systemd-boot desabilitado.
- Kernel params: `mitigations=auto`, `slab_nomerge`, `init_on_alloc/free`, `page_alloc.shuffle`.

### Privacidade

- `fwupd` desabilitado.
- `auditd` habilitado.
- Journald: 200M máximo, retenção de 30 dias, compressão e selo ativados.

### Nix

- `allow-import-from-derivation` desabilitado.
- `trusted-users` restrito a `root` e `livara`.

---

## Tema do greeter (login manager)

### Greeter (regreet)

- Background: ícone violeta do Noctalia (`6afde16e...jpg`) com fit `Cover`.
- GTK theme: `adw-gtk3-dark`.
- Cursor: `Bibata-Modern-Classic`.
- Font: `Cantarell 14`.
- Clock: 24h, locale `pt_BR`.
- CSS completo com tema Noctalia (roxo/violeta):
  - Efeito de vidro fosco no container principal.
  - Botões com tint roxo e transições suaves.
  - Focus rings brilhantes nos campos de entrada.
  - Bordas arredondadas (10-16px) em todos os elementos.
- Mensagem de boas-vindas: "Bem-vindo de volta".
- Pacotes adicionados: `bibata-cursor-theme`, `cantarell-fonts`.

---

## Correção do erro de compilação (attribute 'nixvim' missing)

### Home Manager

- Desktop entry do Neovim corrigido: `${pkgs.nixvim}/bin/nvim` substituído por referência ao pacote do flake `vim-conf`.
- Parâmetro `lib` adicionado ao escopo de `home.nix`.

### Documentação

- `ARCHITECTURE.md` atualizado para refletir a arquitetura NixVim atual.

---

## Migração para nixos-unstable

### Gráficos

- `hardware.opengl` -> `hardware.graphics` (sintaxe moderna do NixOS).
- `driSupport32Bit` -> `enable32Bit` dentro de `hardware.graphics`.

### NVIDIA

- Driver `legacy_580` para GPUs Pascal.

### Home Manager

- `stateVersion` atualizado para `26.11`.

---

## Modularização inicial

- Home Manager integrado ao flake via `home-manager.nixosModules.home-manager` com `useGlobalPkgs` e `useUserPackages`.
- Configuração do usuário centralizada em `home/livara/home.nix`.
- Módulos de recursos em `modules/features/`, configuração do host em `modules/hosts/my-machine/`.
