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

      runtimePkgs = with pkgs; [
        gcc
        clang-tools
        cmake
        gnumake
        maven
        gradle
        jdk21
        jdt-language-server
        spring-boot-cli
        kotlin
        kotlin-language-server
        pyright
        vscode-langservers-extracted
        typescript-language-server
        angular-language-server
        tailwindcss-language-server
        prettier
        ripgrep
        fd
        unzip
        gnutar
        python3
        python3Packages.manim
      ];

      settings.config_directory = "${inputs.lua-conf}";
    };
  };
}
