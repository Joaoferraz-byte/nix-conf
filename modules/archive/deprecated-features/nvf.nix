# modules/features/nvf.nix
#
# Configuração declarativa do Neovim via nvf.
# nvf expõe um módulo NixOS (programs.nvf) que gera toda a configuração
# do editor de forma reproduzível sem precisar de arquivos Lua externos.
#
# Linguagens suportadas: Java/Spring Boot, C/C++, Nix, Python, TypeScript,
# HTML, CSS.
#
# Documentação das opções: https://notashelf.github.io/nvf/options.html
#
# MUDANÇAS FEITAS APÓS BUG DE BUILD:
#   - vim.languages.enableLSP não existe; LSP é habilitado por
#     vim.languages.<lang>.lsp.enable em cada linguagem.
#   - vim.languages.enableDAP não existe; DAP é habilitado por
#     vim.languages.<lang>.dap.enable em cada linguagem.
#   - vim.dashboard.dashboard-nvim não existe; nvf oferece
#     vim.dashboard.startify.enable ou vim.dashboard.alpha.enable.
#   - vim.autocomplete.nvim-cmp.enable existe (confirmado na doc).
#   - vim.debugger.nvim-dap não existe; DAP é configurado por
#     vim.languages.<lang>.dap.enable (e .dap.debugger).
#   - vim.languages.java.extensions.gradle-nvim não existe;
#     maven-nvim existe mas gradle-nvim não tem opção declarativa.
#     Removido para evitar erro de opção inexistente.
#   - vim.options é freeform (open submodule of attrset of anything),
#     portanto options como number, relativenumber, expandtab,
#     smartindent, swapfile, backup, undofile, hlsearch, incsearch,
#     scrolloff são válidas e passadas diretamente para vim.opt.
#   - vim.languages.enableTreesitter existe; vim.languages.enableFormat existe.
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
          # vim.options é um "open submodule of attribute set of anything".
          # Apenas autoindent, cmdheight, cursorlineopt, mouse, shiftwidth,
          # signcolumn, splitbelow, splitright, tabstop, termguicolors, tm,
          # updatetime e wrap têm aliases tipados. As demais são passadas
          # diretamente para vim.opt e os tipos são inferidos pelo Nix.
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
          # dashboard: nvf oferece startify e alpha (não "dashboard-nvim")
          dashboard.startify.enable = true;
          statusline.lualine.enable = true;
          telescope.enable          = true;
          autocomplete.nvim-cmp.enable = true;
          filetree.nvimTree.enable  = true;
          binds.whichKey.enable     = true;
          git.gitsigns.enable       = true;

          # ── Linguagens ───────────────────────────────────────────────────────
          # NÃO existe vim.languages.enableLSP nem vim.languages.enableDAP.
          # LSP e DAP são habilitados individualmente por linguagem.
          languages = {
            enableTreesitter = true;
            enableFormat     = true;

            # Java / Spring Boot
            # LSP: jdtls (Eclipse JDT Language Server)
            # DAP: java-debug-adapter
            java = {
              enable            = true;
              lsp.enable        = true;
              treesitter.enable = true;
              dap.enable        = true;
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

        };
      };
    };
  };
}
