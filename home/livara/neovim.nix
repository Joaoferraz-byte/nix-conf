{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # --- C / C++ ---
    gcc
    clang-tools
    cmake
    gnumake

    # --- Java ---
    maven
    gradle

    # --- Kotlin ---
    kotlin
    kotlin-language-server

    # --- Web / genérico ---
    pyright
    vscode-langservers-extracted
    typescript-language-server

    # --- dependências reais do Telescope ---
    ripgrep
    fd
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk21}";
  };

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
      nvim-dap
      nvim-dap-ui
      nvim-nio
    ];

    initLua = ''
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

      require('nvim-treesitter.configs').setup({
        highlight = { enable = true },
        indent = { enable = true },
      })

      require('java').setup({
        lombok = { enable = true },
        java_test = { enable = true },
        java_debug_adapter = { enable = true },
        spring_boot_tools = { enable = true },
        jdk = { auto_install = false },
      })

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
      lspconfig.ts_ls.setup({ capabilities = capabilities })
      lspconfig.kotlin_language_server.setup({ capabilities = capabilities })

      require('nvim-tree').setup({
        view = { width = 30 },
        git = { enable = true },
        renderer = {
          icons = {
            show = { git = true, folder = true, file = true },
            glyphs = {
              default = "",
              symlink = "",
              folder = {
                arrow_open = "",
                arrow_closed = "",
                default = "",
                open = "",
                empty = "",
                empty_open = "",
                symlink = "",
                symlink_open = "",
              },
              git = {
                unstaged = "",
                staged = "✓",
                untracked = "",
                renamed = "➜",
                unmerged = "",
                deleted = "",
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

      local dap, dapui = require('dap'), require('dapui')
      dapui.setup()
      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

      vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'Debug: Continue' })
      vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
      vim.keymap.set('n', '<leader>du', function() dapui.toggle() end, { desc = 'Debug: Toggle UI' })

      require('dashboard').setup({
        theme = 'hyper',
        config = {
          header = {
            "",
            "",
            "                        LIVARA",
            "",
            "      Neovim declarativo — C/C++ · Java · Kotlin",
            "",
          },
          center = {
            { icon = "  ", desc = "Find File", action = "Telescope find_files", key = "f" },
            { icon = "  ", desc = "New File", action = "enew", key = "n" },
            { icon = "  ", desc = "Recent Files", action = "Telescope oldfiles", key = "r" },
            { icon = "  ", desc = "Explore Files", action = "NvimTreeToggle", key = "e" },
            { icon = "  ", desc = "Configuration", action = "e ~/.config/nvim/init.lua", key = "c" },
            { icon = "  ", desc = "Quit Neovim", action = "qa", key = "q" },
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
}

