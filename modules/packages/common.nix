# modules/packages/common.nix
#
# Pacotes de sistema compartilhados entre máquinas.
# Este módulo é importado por cada host via nixosModules.commonPackages.
# Mantê-lo separado de configuration.nix permite reutilizá-lo em futuros
# hosts sem duplicação e torna o configuration.nix focado apenas em
# configurações específicas da máquina (rede, locale, usuários, boot).
{ ... }: {
  flake.nixosModules.commonPackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # ── Controle de versão ─────────────────────────────────────────────────
      git
      gh

      # ── Aplicações de desktop ──────────────────────────────────────────────
      nautilus        # Gerenciador de arquivos GNOME
      brave           # Navegador web
      vesktop         # Cliente Discord com suporte a Wayland
      kdePackages.okular  # Leitor de PDF
      foliate         # Leitor de e-books (EPUB, MOBI)
      obsidian        # Notas e base de conhecimento

      # ── Jogos ─────────────────────────────────────────────────────────────
      hydralauncher   # Launcher de jogos
      heroic          # Launcher GOG/Epic Games

      # ── Java / Spring Boot ────────────────────────────────────────────────
      # Nota: jdk21 e jdt-language-server também estão nos runtimePkgs do
      # neovim-wrapped.nix para que o LSP funcione dentro do editor.
      # A presença aqui garante disponibilidade global no sistema (ex: terminal,
      # scripts, build tools fora do Neovim).
      jdk21
      jdk8
      jdt-language-server
      spring-boot-cli
    ];
  };
}
