# modules/features/nvf.nix
{ inputs, pkgs, ... }: {
  flake.nixosModules.nvf = { ... }: {
    imports = [ inputs.nvf.nixosModules.default ];

    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          # Tema
          theme = {
            enable = true;
            name = "github-dark";
            style = "dark";
          };

          # Opções Core
          options = {
            number = true;
            relativenumber = true;
            shiftwidth = 2;
            tabstop = 2;
            expandtab = true;
            smartindent = true;
            wrap = false;
            swapfile = false;
            backup = false;
            undofile = true;
            hlsearch = false;
            incsearch = true;
            termguicolors = true;
            scrolloff = 8;
            signcolumn = "yes";
            updatetime = 50;
            colorcolumn = "yes";
          };

          # UI e Dashboard
          dashboard.dashboard-nvim.enable = true;
          statusline.lualine.enable = true;
          telescope.enable = true;
          autocomplete.nvim-cmp.enable = true;
          filetree.nvimTree.enable = true;
          binds.whichKey.enable = true;
          git.gitsigns.enable = true;

          # LSPs e Linguagens
          languages = {
            enableLSP = true;
            enableFormat = true;
            enableTreesitter = true;

            # Java / Spring Boot
            java = {
              enable = true;
              lsp.enable = true;
              treesitter.enable = true;
            };

            # C/C++
            clang = {
              enable = true;
              lsp.enable = true;
              treesitter.enable = true;
              dap.enable = true;
            };

            # Nix
            nix = {
              enable = true;
              lsp.enable = true;
              format.enable = true;
            };

            # Outros do setup antigo
            python.enable = true;
            ts.enable = true;
            html.enable = true;
            css.enable = true;
          };

          # DAP (Debugging)
          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };
        };
      };
    };
  };
}
