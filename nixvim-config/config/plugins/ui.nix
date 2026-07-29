{ ... }:
{
  plugins = {
    nvim-tree = {
      enable = true;
      settings = {
        view = { width = 35; side = "left"; };
        renderer = {
          icons = {
            show = { file = true; folder = true; git = true; };
            glyphs = {
              git = {
                unstaged = "✗";
                staged = "✓";
                unmerged = "";
                renamed = "➜";
                untracked = "★";
                deleted = "⊘";
                ignored = "◌";
              };
            };
          };
        };
        filters = {
          dotfiles = false;
          git_ignored = false;
          custom = [ ".git" "node_modules" ".direnv" ".result" ];
        };
        git = { enable = true; };
        diagnostics = {
          enable = true;
          icons = { hint = "󰠠 "; info = " "; warning = " "; error = " "; };
        };
      };
    };

    lualine = {
      enable = true;
      settings = {
        options.theme = "github_dark";
        sections = {
          lualine_a = [
            { __raw = ''{ 'mode', fmt = function(str) return '▊ ' .. str end }''; }
          ];
          lualine_b = [ "branch" "diff" ];
          lualine_c = [
            { __raw = ''{ 'diagnostics', sources = { 'nvim_lsp', 'nvim_diagnostic' }, symbols = { error = ' ', warn = ' ', info = ' ', hint = '󰠠 ' } }''; }
            { __raw = ''{ 'filename', path = 1, symbols = { modified = '  ', readonly = '  ' } }''; }
          ];
          lualine_x = [
            { __raw = ''{ 'encoding', fmt = string.lower }''; }
            { __raw = ''{ 'fileformat', icons_enabled = true }''; }
          ];
          lualine_y = [ "progress" ];
          lualine_z = [ "location" ];
        };
      };
    };

    dashboard = {
      enable = true;
      settings = {
        theme = "doom";
        config = {
          header = [
            "  "
            "██╗  ██╗██╗██╗      ██████╗ ██╗  ██╗███████╗██████╗ "
            "██║  ██║██║██║     ██╔═══██╗██║ ██╔╝██╔════╝██╔══██╗"
            "███████║██║██║     ██║   ██║█████╔╝ █████╗  ██████╔╝"
            "██╔══██║██║██║     ██║   ██║██╔═██╗ ██╔══╝  ██╔══██╗"
            "██║  ██║██║███████╗╚██████╔╝██║  ██╗███████╗██║  ██║"
            "╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
            "  "
          ];
        };
      };
    };

    toggleterm = {
      enable = true;
      settings = {
        size = 20;
        open_mapping = "[[<c-\\>]]";
        hide_numbers = true;
        shade_terminals = true;
        start_in_insert = true;
        terminal_mappings = true;
        persist_size = true;
        direction = "float";
        close_on_exit = true;
        shell = "zsh";
        float_opts = {
          border = "curved";
          winblend = 3;
        };
      };
    };

    telescope = {
      enable = true;
      extensions = {
        fzf-native.enable = true;
      };
    };
  };
}
