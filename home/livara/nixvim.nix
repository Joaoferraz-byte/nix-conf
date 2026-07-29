{ pkgs, ... }: {
  enable = true;

  # ── Vim Options ─────────────────────────────────────────────────────────────
  opts = {
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
    cursorline     = true;
    mouse          = "a";
    splitbelow     = true;
    splitright     = true;
  };

  # ── Theme: GitHub Dark ─────────────────────────────────────────────────────
  colorschemes.github-theme = {
    enable = true;
    settings = {
      options = {
        transparent = true;
        styles = {
          comments = "italic";
          keywords = "italic";
          functions = "italic";
        };
      };
    };
  };
  colorscheme = "github_dark_default";

  # ── Performance ─────────────────────────────────────────────────────────────
  performance = {
    byteCompileLua = {
      enable      = true;
      nvimRuntime = true;
      configs     = true;
      plugins     = true;
    };
  };

  # ── Keymaps ─────────────────────────────────────────────────────────────────
  keymaps = [
    { key = "<space>"; action = "<cmd>noh<CR>"; mode = [ "n" ]; options = { silent = true; nowait = true; desc = "Clear search highlight"; }; }

    # Buffer
    { key = "<leader>bd"; action = "<cmd>bd<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Delete buffer"; }; }
    { key = "<leader>x"; action = "<cmd>bd<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Delete buffer alt"; }; }
    { key = "<C-s>"; action = "<cmd>w<CR>"; mode = [ "n" "i" ]; options = { silent = true; desc = "Save file"; }; }
    { key = "<leader>q"; action = "<cmd>qa<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Quit all buffers"; }; }

    # LSP
    { key = "gd"; action = "<cmd>lua vim.lsp.buf.definition()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Go to definition"; }; }
    { key = "gD"; action = "<cmd>lua vim.lsp.buf.declaration()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Go to declaration"; }; }
    { key = "gi"; action = "<cmd>lua vim.lsp.buf.implementation()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Go to implementation"; }; }
    { key = "gr"; action = "<cmd>lua vim.lsp.buf.references()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Go to references"; }; }
    { key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Hover documentation"; }; }
    { key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Rename symbol"; }; }
    { key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; mode = [ "n" "v" ]; options = { silent = true; desc = "Code action"; }; }
    { key = "<leader>ds"; action = "<cmd>lua vim.diagnostic.setloclist()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Diagnostic location list"; }; }

    # Telescope
    { key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Find files"; }; }
    { key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Live grep"; }; }
    { key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Find buffers"; }; }
    { key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Help tags"; }; }
    { key = "<leader>fo"; action = "<cmd>Telescope oldfiles<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Old files"; }; }
    { key = "<leader>fd"; action = "<cmd>Telescope diagnostics<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Diagnostics"; }; }
    { key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Document symbols"; }; }

    # Filetree
    { key = "<leader>e"; action = "<cmd>NvimTreeToggle<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Toggle file tree"; }; }

    # Terminal
    { key = "<C-\\>"; action = "<cmd>ToggleTerm direction=float<CR>"; mode = [ "n" "t" ]; options = { silent = true; desc = "Toggle floating terminal"; }; }

    # DAP
    { key = "<leader>db"; action = "<cmd>lua require('dap').toggle_breakpoint()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Toggle breakpoint"; }; }
    { key = "<leader>dc"; action = "<cmd>lua require('dap').continue()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Continue debugging"; }; }
    { key = "<leader>dn"; action = "<cmd>lua require('dap').step_over()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Step over"; }; }
    { key = "<leader>di"; action = "<cmd>lua require('dap').step_into()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Step into"; }; }
    { key = "<leader>do"; action = "<cmd>lua require('dap').step_out()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Step out"; }; }
    { key = "<leader>dr"; action = "<cmd>lua require('dapui').toggle()<CR>"; mode = [ "n" ]; options = { silent = true; desc = "Toggle DAP UI"; }; }

    # Visual movement
    { key = "j"; action = "gj"; mode = [ "n" "v" ]; options = { silent = true; desc = "Move down visually"; }; }
    { key = "k"; action = "gk"; mode = [ "n" "v" ]; options = { silent = true; desc = "Move up visually"; }; }
  ];

  # ── Autocmds ────────────────────────────────────────────────────────────────
  autoGroups = {
    highlight_yank = { };
    trim_whitespace = { };
  };

  autoCmd = [
    {
      event   = "FileType";
      pattern = [ "qf" "help" "man" "lspinfo" ];
      command = "nnoremap <buffer> <silent> q :close<CR>";
    }
    {
      event   = "TextYankPost";
      group   = "highlight_yank";
      command = "lua vim.highlight.on_yank { higroup = 'Visual', timeout = 200 }";
    }
    {
      event   = "BufWritePre";
      group   = "trim_whitespace";
      command = "%s/\\s\\+$//e";
    }
    {
      event   = [ "InsertEnter" "TermOpen" ];
      pattern = "*";
      command = "setlocal norelativenumber";
    }
    {
      event   = [ "InsertLeave" "TermClose" ];
      pattern = "*";
      command = "setlocal relativenumber";
    }
  ];

  # ── LSP ─────────────────────────────────────────────────────────────────────
  plugins.lsp = {
    enable = true;
    servers = {
      jdtls = {
        enable  = true;
        package = pkgs.jdt-language-server;
        cmd = [
          "jdtls"
          "--jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar"
        ];
        settings = {
          java = {
            configuration = {
              runtimes = [
                { name = "JavaSE-21"; path = "${pkgs.jdk21}"; default = true; }
                { name = "JavaSE-8"; path = "${pkgs.jdk8}"; }
              ];
            };
            codeAction = { sortMembers = { enable = true; }; };
            signatureHelp = { enabled = true; };
            contentProvider = { preferred = "fernflower"; };
            completion = {
              favoriteStaticMembers = [
                "org.junit.jupiter.api.Assertions.*"
                "org.mockito.Mockito.*"
                "org.assertj.core.api.Assertions.*"
              ];
              importOrder = [ "java" "jakarta" "javax" "com" "org" ];
            };
            sources = {
              organizeImports = {
                starThreshold = 9999;
                staticThreshold = 9999;
              };
            };
            format = {
              enable = true;
              settings = { profile = "GoogleStyle"; };
            };
          };
        };
      };
      clangd = {
        enable = true;
        settings = {
          clangd = {
            arguments = [
              "--background-index"
              "--clang-tidy"
              "--header-insertion=iwyu"
              "--completion-style=detailed"
              "--function-arg-placeholders"
              "--fallback-style=llvm"
            ];
          };
        };
      };
      nil_ls = { enable = true; };
      pyright = { enable = true; };
      ts_ls = { enable = true; };
      html = { enable = true; };
      cssls = { enable = true; };
      jsonls = { enable = true; };
    };
  };

  # ── Completion ──────────────────────────────────────────────────────────────
  plugins.lspkind = {
    enable = true;
    cmp = {
      enable = true;
      menu = {
        nvim_lsp = "[LSP]";
        buffer   = "[BUF]";
        path     = "[FILE]";
        luasnip  = "[SNIP]";
      };
    };
  };

  plugins.cmp-nvim-lsp = { enable = true; };
  plugins.cmp-buffer = { enable = true; };
  plugins.cmp-path = { enable = true; };
  plugins.cmp-luasnip = { enable = true; };
  plugins.cmp-treesitter = { enable = true; };

  plugins.luasnip = {
    enable = true;
    settings = {
      enable_autosnippets = true;
    };
    fromLua = [
      { paths = "./snippets"; }
    ];
    fromVscode = [
      { lazyLoad = true; }
    ];
  };

  # ── Treesitter ──────────────────────────────────────────────────────────────
  plugins.treesitter = {
    enable = true;
    settings = {
      indent = { enable = true; };
      highlight = { enable = true; };
      ensure_installed = [
        "java" "kotlin" "groovy" "xml" "html" "css" "scss"
        "c" "cpp" "cmake" "make" "bash" "zsh" "fish" "sh"
        "nix" "lua" "python" "javascript" "typescript" "tsx"
        "json" "yaml" "toml" "vim" "vimdoc" "regex" "markdown"
        "go" "rust" "ruby" "php"
      ];
    };
  };

  plugins.treesitter-context = {
    enable = true;
    settings = {
      max_lines  = 3;
      min_lines  = 1;
      trim_scope = "outer";
    };
  };

  # ── UI ──────────────────────────────────────────────────────────────────────
  plugins.nvim-tree = {
    enable = true;
    settings = {
      view = { width = 35; side = "left"; };
      renderer = {
        icons = {
          show = { file = true; folder = true; git = true; };
          glyphs = {
            git = {
              unstaged  = "✗";
              staged    = "✓";
              unmerged  = "";
              renamed   = "➜";
              untracked = "★";
              deleted   = "⊘";
              ignored   = "◌";
            };
          };
        };
      };
      filters = {
        dotfiles    = false;
        git_ignored = false;
        custom      = [ ".git" "node_modules" ".direnv" ".result" ];
      };
      git = { enable = true; };
      diagnostics = {
        enable = true;
        icons = { hint = "󰠠 "; info = " "; warning = " "; error = " "; };
      };
    };
  };

  plugins.lualine = {
    enable = true;
    settings = {
      theme = "github_dark";
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

  plugins.dashboard = {
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
          "                                                      "
        ];
        shortcut = [
          { __raw = ''{ icon = '  ', desc = 'Recent files', action = 'Telescope oldfiles', key = 'f' }''; }
          { __raw = ''{ icon = '  ', desc = 'Find files', action = 'Telescope find_files', key = 'o' }''; }
          { __raw = ''{ icon = '  ', desc = 'Config files', action = 'Telescope find_files search_dirs={\"~/.config/nvim\"}', key = 'c' }''; }
          { __raw = ''{ icon = '  ', desc = 'Session', action = 'SessionRestore', key = 's' }''; }
          { __raw = ''{ icon = '  ', desc = 'Quit', action = 'qa', key = 'q' }''; }
        ];
        footer = [ "Powered by NixVim" ];
      };
    };
  };

  # ── Git ─────────────────────────────────────────────────────────────────────
  plugins.gitsigns = {
    enable = true;
    settings = {
      signs = {
        add          = { text = "▎"; };
        change       = { text = "▎"; };
        delete       = { text = "_"; };
        topdelete    = { text = "‾"; };
        changedelete = { text = "~"; };
      };
      on_attach = ''
        function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          map('n', ']c', function() gs.next_hunk() end, { desc = 'Next hunk' })
          map('n', '[c', function() gs.prev_hunk() end, { desc = 'Prev hunk' })
          map('n', '<leader>gs', function() gs.stage_hunk() end, { desc = 'Stage hunk' })
          map('n', '<leader>gr', function() gs.reset_hunk() end, { desc = 'Reset hunk' })
          map('n', '<leader>gS', function() gs.stage_buffer() end, { desc = 'Stage buffer' })
          map('n', '<leader>gu', function() gs.undo_stage_hunk() end, { desc = 'Undo stage hunk' })
          map('n', '<leader>gR', function() gs.reset_buffer() end, { desc = 'Reset buffer' })
          map('n', '<leader>gp', function() gs.preview_hunk() end, { desc = 'Preview hunk' })
          map('n', '<leader>gb', function() gs.blame_line { full = true } end, { desc = 'Blame line' })
          map('n', '<leader>gd', function() gs.diffthis() end, { desc = 'Diff this' })
          map('n', '<leader>gD', function() gs.diffthis('~') end, { desc = 'Diff this ~' })
          map('n', '<leader>gtb', function() gs.toggle_current_line_blame() end, { desc = 'Toggle blame' })
          map('n', '<leader>gtd', function() gs.toggle_deleted() end, { desc = 'Toggle deleted' })
        end
      '';
    };
  };

  # ── Telescope ───────────────────────────────────────────────────────────────
  plugins.telescope = {
    enable = true;
    settings = {
      defaults = {
        vimgrep_arguments = [
          "rg" "--color=never" "--no-heading"
          "--with-filename" "--line-number" "--column"
          "--smart-case"
        ];
        prompt_prefix = "   ";
        selection_caret = "▸ ";
        path_display = [ "smart" ];
        file_ignore_patterns = [
          "node_modules" ".git/" "dist/" "build/"
          ".direnv/" ".result/" "target/" "out/"
        ];
      };
      pickers = {
        find_files = { hidden = false; };
        live_grep = {
          additional_args = ''
            function()
              return { "--hidden" }
            end
          '';
        };
      };
    };
  };

  plugins.telescope-fzf-native = { enable = true; };

  # ── Which-key ───────────────────────────────────────────────────────────────
  plugins.which-key = {
    enable = true;
    settings = {
      preset = "helix";
      icons = { rules = true; };
      spec = [
        { __raw = ''{ '<leader>f', group = 'find' }''; }
        { __raw = ''{ '<leader>g', group = 'git' }''; }
        { __raw = ''{ '<leader>d', group = 'debug' }''; }
        { __raw = ''{ '<leader>c', group = 'code' }''; }
        { __raw = ''{ '<leader>b', group = 'buffer' }''; }
      ];
    };
  };

  # ── Utilities ───────────────────────────────────────────────────────────────
  plugins.indent-blankline = {
    enable = true;
    settings = {
      scope = { enabled = true; show_start = false; };
      indent = { char = "│"; };
    };
  };

  plugins.comment = { enable = true; };
  plugins.nvim-autopairs = { enable = true; };
  plugins.nvim-surround = { enable = true; };
  plugins.todo-comments = { enable = true; };
  plugins.toggleterm = {
    enable = true;
    settings = {
      direction = "float";
      float_opts = { border = "curved"; };
    };
  };

  # ── DAP ─────────────────────────────────────────────────────────────────────
  plugins.nvim-dap = {
    enable = true;
    settings = {
      signs = {
        dapBreakpoint         = { text = "●"; texthl = "DapBreakpoint"; };
        dapBreakpointCondition = { text = "●"; texthl = "DapBreakpointCondition"; };
        dapLogPoint           = { text = "◆"; texthl = "DapLogPoint"; };
        dapStopped            = { text = "▶"; texthl = "DapStopped"; };
        dapBreakpointRejected = { text = "○"; texthl = "DapBreakpointRejected"; };
      };
    };
  };

  plugins.nvim-dap-ui = { enable = true; };

  # ── Extra Plugins ───────────────────────────────────────────────────────────
  extraPlugins = with pkgs.vimPlugins; [
    nvim-web-devicons
  ];

  # ── Lua Config ──────────────────────────────────────────────────────────────
  extraConfigLua = ''
    -- DAP: CodeLLDB (C/C++)
    local dap = require('dap')
    dap.adapters.codelldb = {
      type = 'server',
      port = "${"$"}{port}",
      executable = {
        command = "codelldb",
        args = { "--port", "${"$"}{port}" },
      }
    }

    dap.configurations.cpp = {
      {
        name = "Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = "${"$"}{workspaceFolder}",
        stopOnEntry = false,
      },
      {
        name = "Attach to process",
        type = "codelldb",
        request = "attach",
        pid = require('dap.utils').pick_process,
        cwd = "${"$"}{workspaceFolder}",
      },
    }
    dap.configurations.c = dap.configurations.cpp

    dap.configurations.python = {
      {
        name = "Launch file",
        type = "python",
        request = "launch",
        program = "${"$"}{file}",
        pythonPath = function()
          return 'python3'
        end,
      },
    }

    -- DAP UI setup
    local dapui = require('dapui')
    dapui.setup({
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.25 },
            { id = "breakpoints", size = 0.25 },
            { id = "stacks", size = 0.25 },
            { id = "watches", size = 0.25 },
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          size = 15,
          position = "bottom",
        },
      },
      floating = {
        max_height = nil,
        max_width = nil,
        border = "rounded",
      },
    })

    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    -- LSP diagnostics
    vim.diagnostic.config({
      virtual_text = { source = "always", spacing = 2 },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- Format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        local bufnr = args.buf
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        for _, client in ipairs(clients) do
          if client.supports_method("textDocument/formatting") then
            vim.lsp.buf.format({ bufnr = bufnr, async = true })
            return
          end
        end
      end,
    })

    -- Cursor hold highlight
    vim.api.nvim_create_augroup("CursorHoldHighlight", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = "CursorHoldHighlight",
      pattern = "*",
      callback = function() vim.lsp.buf.document_highlight() end,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = "CursorHoldHighlight",
      pattern = "*",
      callback = function() vim.lsp.buf.clear_references() end,
    })

    -- Nix formatting via nixfmt
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "nix",
      callback = function()
        vim.bo.formatexpr = "v:lua.vim.lsp.formatexpr(#{timeout_ms=500})"
      end,
    })
  '';
}
