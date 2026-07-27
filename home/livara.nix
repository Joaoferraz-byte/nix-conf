{ config, pkgs, inputs, ... }:

{
  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "24.05";

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
  };


  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    llvmPackages.clang-unwrapped # clangd está aqui no unstable
    pyright
    vscode-langservers-extracted
    typescript-language-server
    ripgrep
    fd
    python3Packages.manim
    nerd-fonts.jetbrains-mono
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

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
    ];

    extraLuaConfig = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.termguicolors = true
      vim.opt.background = "dark"
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 4
      vim.opt.tabstop = 4
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.cursorline = true
      vim.opt.signcolumn = "yes"
      vim.opt.updatetime = 250
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      vim.cmd("colorscheme github_dark")
      vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "NonText", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })

      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require('java').setup({
        lombok = { enable = true },
        java_test = { enable = true },
        java_debug_adapter = { enable = true },
        spring_boot_tools = { enable = true },
        jdk = { auto_install = false },
      })
      vim.lsp.enable('jdtls')

      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        })
      })

      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local jdtls_root_dir = function(fname)
        local root_patterns = {"pom.xml", "build.gradle", ".git"}
        local project_root = require('lspconfig.util').root_pattern(unpack(root_patterns))(fname)
        if project_root then return project_root end

        local home_projects = vim.fn.expand('~/Projects')
        if vim.fn.isdirectory(home_projects) and string.find(fname, home_projects, 1, true) then
          return home_projects
        end
        return vim.fn.getcwd()
      end

      lspconfig.jdtls.setup({
        capabilities = capabilities,
        root_dir = jdtls_root_dir,
      })

      lspconfig.clangd.setup({ capabilities = capabilities })
      lspconfig.pyright.setup({ capabilities = capabilities })
      lspconfig.html.setup({ capabilities = capabilities })
      lspconfig.cssls.setup({ capabilities = capabilities })
      lspconfig.tsserver.setup({ capabilities = capabilities })

      require('nvim-tree').setup({
        view = { width = 30 },
        git = { enable = true },
        renderer = {
          icons = {
            show = { git = true, folder = true, file = true },
            glyphs = {
              default = "",
              symlink = "",
              folder = {
                arrow_open = "",
                arrow_closed = "",
                default = "",
                open = "",
                empty = "",
                empty_open = "",
                symlink = "",
                symlink_open = "",
              },
              git = {
                unstaged = "",
                staged = "✓",
                untracked = "",
                renamed = "➜",
                unmerged = "",
                deleted = "",
                ignored = "◌",
              },
            },
          },
        },
      })

      require('lualine').setup({
        options = {
          theme = 'github-dark',
          globalstatus = true,
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
      })

      require('which-key').setup()
      require('gitsigns').setup()
      require('bufferline').setup()

      require('dashboard').setup({
        theme = 'hyper',
        config = {
          header = {
            "                                                               ",
            " █████╗ ███╗   ██╗██╗   ██╗ █████╗ ███╗   ██╗██╗    ██╗",
            "██╔══██╗████╗  ██║██║   ██║██╔══██╗████╗  ██║██║    ██║",
            "███████║██╔██╗ ██║██║   ██║███████║██╔██╗ ██║██║ █╗ ██║",
            "██╔══██║██║╚██╗██║██║   ██║██╔══██║██║╚██╗██║██║███╗██║",
            "██║  ██║██║ ╚████║╚██████╔╝██║  ██║██║ ╚████║╚███╔███╝",
            "╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚══╝╚══╝ ",
            "                                                               ",
            "  A modern, modular, and declarative Neovim configuration.  ",
            "                                                               ",
          },
          center = {
            { icon = "  ", desc = "Find File", action = "Telescope find_files", key = "f" },
            { icon = "  ", desc = "New File", action = "enew", key = "n" },
            { icon = "  ", desc = "Recent Files", action = "Telescope oldfiles", key = "r" },
            { icon = "  ", desc = "Explore Files", action = "NvimTreeToggle", key = "e" },
            { icon = "  ", desc = "Configuration", action = "e ~/.config/nvim/init.lua", key = "c" },
            { icon = "  ", desc = "Quit Neovim", action = "qa", key = "q" },
          },
        },
      })

      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })
      vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find Files' })
      vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', { desc = 'Live Grep' })
      vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { desc = 'Find Buffers' })
      vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', { desc = 'Help Tags' })
      vim.keymap.set('n', '<leader>jb', ':JavaBuildBuildWorkspace<CR>', { desc = 'Java Build' })
      vim.keymap.set('n', '<leader>jr', ':JavaRunnerRunMain<CR>', { desc = 'Java Run' })
      vim.keymap.set('n', '<leader>jt', ':JavaTestRunCurrentClass<CR>', { desc = 'Java Test' })
      vim.keymap.set('n', '<leader>jd', ':JavaDapConfig<CR>', { desc = 'Java DAP' })
      vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move left' })
      vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move down' })
      vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move up' })
      vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move right' })
    '';
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
        decorations = "none";
      };
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        size = 12.0;
      };
      colors = {
        primary = { background = "#0d1117"; foreground = "#b3b1ad"; };
        normal = {
          black = "#484f58"; red = "#ff7b72"; green = "#3fb950"; yellow = "#d29922";
          blue = "#58a6ff"; magenta = "#bc8cff"; cyan = "#39c5cf"; white = "#b1bac4";
        };
        bright = {
          black = "#6e7681"; red = "#ffa198"; green = "#56d364"; yellow = "#e3b341";
          blue = "#79c0ff"; magenta = "#d2a8ff"; cyan = "#56d4dd"; white = "#f0f6fc";
        };
      };
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "text/plain" = [ "nvim.desktop" ];
      "text/x-java" = [ "nvim.desktop" ];
      "text/x-csrc" = [ "nvim.desktop" ];
      "text/x-c++src" = [ "nvim.desktop" ];
      "text/x-python" = [ "nvim.desktop" ];
      "application/json" = [ "nvim.desktop" ];
      "text/html" = [ "nvim.desktop" ];
      "text/css" = [ "nvim.desktop" ];
      "application/javascript" = [ "nvim.desktop" ];
    };
  };

  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "alacritty -e nvim %F";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/x-java" ];
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    videos = "${config.home.homeDirectory}/Videos";
  };
}
