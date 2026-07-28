{
  self, inputs, ...
}:
{
  flake.nixosModules.neovimWrapped = { pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.myNeovim
    ];
  };

  perSystem = {
    pkgs, ...
  }:
  {
    packages.myNeovim = inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;

      # ---- Plugins (antes chamado de `plugins`) ----
      # No BirdeeHub/nix-wrapper-modules a opção correta é `specs`.
      # Cada atributo em `specs` vira um "spec" no DAG de inicialização do Neovim.
      # Aqui agrupamos os plugins de startup em um único spec chamado `general`.
      # Veja: https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/neovim.html
      specs.general = with pkgs.vimPlugins; [
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip
        github-nvim-theme
        nvim-java
        nvim-tree-lua
        nvim-web-devicons
        lualine-nvim
        telescope-nvim
        plenary-nvim
        vim-fugitive
        gitsigns-nvim
        which-key-nvim
        bufferline-nvim
        snacks-nvim
        nvim-dap
        nvim-dap-ui
        nvim-nio
      ];

      # ---- Ferramentas/LSPs no PATH (antes chamado de `extraPackages`) ----
      # `extraPackages` está DEPRECADO no wrapper e será removido em 31/08/2026.
      # A opção correta (e não-deprecada) é `runtimePkgs`, que coloca os binários no PATH do Neovim.
      runtimePkgs = with pkgs; [
        # --- C / C++ ---
        gcc
        clang-tools
        cmake
        gnumake

        # --- Java ---
        maven
        gradle
        jdk21 # Para jdt-language-server
        jdt-language-server
        spring-boot-cli

        # --- Kotlin ---
        kotlin
        kotlin-language-server

        # --- Web / genérico ---
        pyright
        vscode-langservers-extracted
        typescript-language-server
        angular-language-server # Para Angular
        tailwindcss-language-server # Para Tailwind CSS
        prettier # Para formatação de código web

        # --- Dependências do Telescope ---
        ripgrep
        fd

        # --- Manim ---
        python3 # Para Manim
        manim # Para Manim
      ];

      # ---- Diretório de configuração (substitui o `initLua`) ----
      # O neovim wrapper NÃO tem uma opção `initLua`.
      # O jeito oficial de injetar sua configuração (init.lua + lua/) é apontar
      # `settings.config_directory` para um diretório que contenha um `init.lua`.
      #
      # O wrapper cria um spec chamado `INIT_MAIN` que faz `dofile(cfgdir .. "/init.lua")`,
      # então o `init.lua` do lua-conf será carregado automaticamente, junto com todo
      # o conteúdo de `lua/` (que entra no runtimepath como uma config dir normal).
      #
      # Como `inputs.lua-conf` é um input com `flake = false`, ele é um path puro
      # (uma store path), então é seguro usá-lo aqui.
      settings.config_directory = "${inputs.lua-conf}";
    };
  };
}
