# Relatório de Revisão de Arquitetura — nix-conf

## Visão Geral

Este documento registra as revisões arquiteturais aplicadas ao repositório `nix-conf`, uma configuração NixOS baseada em flake para um desktop com GPU NVIDIA, compositor Niri Wayland e Home Manager. A arquitetura atual segue o padrão de módulos isolados em `modules/features/` importados por host-specific configuration em `modules/hosts/<host>/`.

---

## Revisões Aplicadas

### 1. Correção da referência do pacote NixVim

**Problema:** O desktop entry do Neovim em `home.nix` referenciava `${pkgs.nixvim}/bin/nvim`, um atributo inexistente no escopo do Home Manager.

**Solução:** Substituído por `${inputs.vim-conf.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/nvim`, que referencia o derivation real construído pelo flake `vim-conf`.

### 2. Tema moderno do greeter (Noctalia)

**Arquivo:** `modules/features/greeter.nix`

O greeter foi completamente redesenhado com um tema Noctalia: background usando o ícone violeta do Noctalia, CSS com acentos roxos (#7c3aed, #8b5cf6), efeito de vidro fosco, e tipografia Cantarell.

### 3. Auditoria de segurança e hardening

**Arquivo:** `modules/features/system-hardening.nix`

Módulo reescrito com base no NixOS Wiki Security e práticas de kernel hardening. Inclui firewall stateful, sysctl de kernel, restrições de boot, auditd, e proteção de memória.

### 4. Ativação do módulo system-hardening

O módulo `system-hardening` estava definido mas não importado no `configuration.nix`. Foi adicionado ao bloco `imports`.

---

## Dívidas Técnicas Identificadas

1. **Pino de `nixpkgs-stable` para o Niri**: Mantido por falhas transientes de `libdisplay-info` no unstable. Deve ser removido quando corrigido upstream.
2. **Ausência de CI/CD**: Sem GitHub Actions para validar o flake automaticamente.
3. **Consistência de inputs**: O `nixvim` aparece como input direto do `nix-conf` e também aninhado dentro do `vim-conf`. Deve ser consolidado quando possível.
