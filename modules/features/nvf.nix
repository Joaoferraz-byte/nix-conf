# modules/features/nvf.nix
#
# Configuração declarativa do Neovim via nvf.
# nvf expõe um módulo NixOS (programs.nvf) que gera toda a configuração
# do editor de forma reproduzível sem precisar de arquivos Lua externos.
#
# Linguagens suportadas: Java/Spring Boot, C/C++, Nix, Python, TypeScript,
# HTML, CSS.
{ inputs, ... }: {
  flake.nixosModules.nvf = { ... }: {
    imports = [ inputs.nvf.nixosModules.default ];

    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          # ── Tema ────────────────────────────────────────────────────────────
          theme = {
            enable = true;
            name = "github-dark";
            style = "dark";
          };

          # ── Opções Core ─────────────────────────────────────────────────────
          # vim.options é um atributo freeform; os tipos são inferidos pelo Nix.
          # Apenas as opções documentadas em nvf/modules/wrapper/rc/options.nix
          # têm aliases tipados; as demais são passadas diretamente para vim.opt.
          options = {
            number         = true;
            relativenumber = true;
            shiftwidth     = 2;
            tabstop        = 2;
            expandtab      = true;
            smartindent    = true;
            wrap           = false;
            swapfile       = false;
            backup         = false;
            undofile       = true;
            hlsearch       = false;
            incsearch      = true;
            termguicolors  = true;
            scrolloff      = 8;
            signcolumn     = "yes";
            updatetime     = 50;
          };

          # ── UI e Produtividade ───────────────────────────────────────────────
          dashboard.dashboard-nvim.enable = true;
          statusline.lualine.enable       = true;
          telescope.enable                = true;
          autocomplete.nvim-cmp.enable    = true;
          filetree.nvimTree.enable        = true;
          binds.whichKey.enable           = true;
          git.gitsigns.enable             = true;

          # ── Linguagens ───────────────────────────────────────────────────────
          languages = {
            enableLSP        = true;
            enableFormat     = true;
            enableTreesitter = true;

            # Java / Spring Boot
            # LSP: jdtls (Eclipse JDT Language Server)
            # DAP: java-debug-adapter via nvim-jdtls
            java = {
              enable          = true;
              lsp.enable      = true;
              treesitter.enable = true;
              dap.enable      = true;
              # gradle-nvim: integração com Gradle para projetos Spring Boot
              extensions.gradle-nvim.enable = true;
            };

            # C/C++
            # LSP: clangd
            # DAP: codelldb
            clang = {
              enable            = true;
              lsp.enable        = true;
              treesitter.enable = true;
              dap.enable        = true;
            };

            # Nix
            nix = {
              enable          = true;
              lsp.enable      = true;
              format.enable   = true;
            };

            # Python
            python = {
              enable = true;
            };

            # TypeScript / JavaScript
            typescript = {
              enable = true;
            };

            # HTML / CSS
            html.enable = true;
            css.enable  = true;
          };

          # ── DAP (Debugging) ──────────────────────────────────────────────────
          debugger.nvim-dap = {
            enable    = true;
            ui.enable = true;
          };
        };
      };
    };
  };
}
