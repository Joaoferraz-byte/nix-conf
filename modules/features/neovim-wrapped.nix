{
  self, inputs, ...
}:
{
  perSystem = {
    pkgs, lib, system, ...
  }:
  {
    packages.myNeovim = inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;
      # Adicione aqui os plugins que você quer que o wrapper gerencie
      plugins = with pkgs.vimPlugins; [
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        nvim-cmp
        cmp-nvim-lsp
        luasnip
        github-nvim-theme
        nvim-jdtls
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
        dashboard-nvim
        nvim-dap
        nvim-dap-ui
        nvim-nio
      ];

      # Adicione aqui os LSPs e outras ferramentas que o Neovim precisa
      extraBinPath = with pkgs; [
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
        nodePackages.prettier # Para formatação de código web

        # --- Dependências do Telescope ---
        ripgrep
        fd

        # --- Manim ---
        python3 # Para Manim
        python3Packages.manim # Para Manim
      ];

      # O initLua será o seu arquivo de configuração principal do Neovim
      initLua = builtins.readFile ./nvim-config/init.lua;
    };
  };
}
