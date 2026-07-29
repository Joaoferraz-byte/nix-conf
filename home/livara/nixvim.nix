# home/livara/nixvim.nix
#
# Configuração completa do Neovim via NixVim (nix-community/nixvim).
# NixVim é escolhido sobre NVF por:
#   - Maturidade: 2.900+ stars, 4.700+ commits, 3 mantenedores
#   - Flexibilidade: settings aceita qualquer attrset → Lua table
#   - Escape hatch: extraConfigLua para Lua bruto quando Nix não basta
#   - Completude: keymaps, opts, colorschemes, autocmds, plugins, performance
#   - Estabilidade: testado contra nixpkgs revision, sem enum types quebrando
#
# Linguagens: Java/Spring Boot, C/C++, Nix, Python, TypeScript, HTML, CSS
# Features: LSP, DAP, treesitter, completion, filetree, statusline,
#           dashboard, keybinds, automações, git, telescope, which-key.
#
# Estrutura: Este arquivo é importado via programs.nixvim.imports em home.nix.
#            Assim não precisamos prefixar tudo com programs.nixvim.
{ pkgs, ... }: {
  # ── Core ────────────────────────────────────────────────────────────────────
  enable = true;

  # ── Opções do Vim ───────────────────────────────────────────────────────────
  # opts traduz para vim.opt.<name> no init.lua gerado.
  opts = {
    number            = true;
    relativenumber    = true;
    shiftwidth        = 2;
    tabstop           = 2;
    expandtab         = true;
    smartindent       = true;
    wrap              = false;
    swapfile          = false;
    backup            = false;
    undofile          = true;
    hlsearch          = false;
    incsearch         = true;
    termguicolors     = true;
    scrolloff         = 8;
    signcolumn        = "yes";
    updatetime        = 50;
    cursorline        = true;
    # Mouse em todos os modos
    mouse             = "a";
    # Dividir janelas abaixo e à direita
    splitbelow        = true;
    splitright        = true;
  };

  # ── Tema ────────────────────────────────────────────────────────────────────
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";    # darkest variante
      transparent_background = true;
      integrations = {
        nvimtree   = true;
        telescope  = true;
        which_key  = true;
        gitsigns   = true;
        lualine    = true;
        treesitter = true;
        native_lsp = {
          enabled = true;
          underlines = {
            errors       = [ "undercurl" ];
            hints        = [ "undercurl" ];
            warnings     = [ "undercurl" ];
            information  = [ "undercurl" ];
          };
        };
        dap = {
          enableUI       = true;
          enableDapVirtualText = true;
        };
      };
    };
  };
  colorscheme = "catppuccin";

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
  # Mapeamentos principais do editor. Cada item tem:
  #   key:     atalho
  #   action:  comando ou remap
  #   mode:    modo(s) do vim (n=normal, i=insert, v=visual, t=terminal)
  #   options: { silent = true } por padrão
  keymaps = [
    # ── Líder ─────────────────────────────────────────────────────────────────
    # Espaço como líder (padrão NixVim já define, mas explicitamos)
    {
      key     = "<space>";
      action  = "<cmd>noh<CR>";
      mode    = [ "n" ];
      options = { silent = true; nowait = true; desc = "Clear search highlight"; };
    }

    # ── Buffer / Navegação ────────────────────────────────────────────────────
    {
      key     = "<leader>bd";
      action  = "<cmd>bd<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Delete buffer"; };
    }
    {
      key     = "<C-s>";
      action  = "<cmd>w<CR>";
      mode    = [ "n" "i" ];
      options = { silent = true; desc = "Save file"; };
    }
    {
      key     = "<leader>q";
      action  = "<cmd>qa<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Quit all buffers"; };
    }

    # ── LSP ───────────────────────────────────────────────────────────────────
    {
      key     = "gd";
      action  = "<cmd>lua vim.lsp.buf.definition()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Go to definition"; };
    }
    {
      key     = "gD";
      action  = "<cmd>lua vim.lsp.buf.declaration()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Go to declaration"; };
    }
    {
      key     = "gi";
      action  = "<cmd>lua vim.lsp.buf.implementation()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Go to implementation"; };
    }
    {
      key     = "gr";
      action  = "<cmd>lua vim.lsp.buf.references()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Go to references"; };
    }
    {
      key     = "K";
      action  = "<cmd>lua vim.lsp.buf.hover()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Hover documentation"; };
    }
    {
      key     = "<leader>rn";
      action  = "<cmd>lua vim.lsp.buf.rename()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Rename symbol"; };
    }
    {
      key     = "<leader>ca";
      action  = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      mode    = [ "n" "v" ];
      options = { silent = true; desc = "Code action"; };
    }
    {
      key     = "<leader>ds";
      action  = "<cmd>lua vim.diagnostic.setloclist()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Diagnostic location list"; };
    }

    # ── Telescope ─────────────────────────────────────────────────────────────
    {
      key     = "<leader>ff";
      action  = "<cmd>Telescope find_files<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Find files"; };
    }
    {
      key     = "<leader>fg";
      action  = "<cmd>Telescope live_grep<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Live grep"; };
    }
    {
      key     = "<leader>fb";
      action  = "<cmd>Telescope buffers<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Find buffers"; };
    }
    {
      key     = "<leader>fh";
      action  = "<cmd>Telescope help_tags<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Help tags"; };
    }
    {
      key     = "<leader>fo";
      action  = "<cmd>Telescope oldfiles<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Old files"; };
    }
    {
      key     = "<leader>fd";
      action  = "<cmd>Telescope diagnostics<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Diagnostics"; };
    }
    {
      key     = "<leader>fs";
      action  = "<cmd>Telescope lsp_document_symbols<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Document symbols"; };
    }

    # ── Filetree (nvim-tree) ─────────────────────────────────────────────────
    {
      key     = "<leader>e";
      action  = "<cmd>NvimTreeToggle<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Toggle file tree"; };
    }

    # ── Terminal ──────────────────────────────────────────────────────────────
    {
      key     = "<C-\\>";
      action  = "<cmd>ToggleTerm direction=float<CR>";
      mode    = [ "n" "t" ];
      options = { silent = true; desc = "Toggle floating terminal"; };
    }

    # ── DAP (Debug) ───────────────────────────────────────────────────────────
    {
      key     = "<leader>db";
      action  = "<cmd>lua require('dap').toggle_breakpoint()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Toggle breakpoint"; };
    }
    {
      key     = "<leader>dc";
      action  = "<cmd>lua require('dap').continue()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Continue debugging"; };
    }
    {
      key     = "<leader>dn";
      action  = "<cmd>lua require('dap').step_over()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Step over"; };
    }
    {
      key     = "<leader>di";
      action  = "<cmd>lua require('dap').step_into()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Step into"; };
    }
    {
      key     = "<leader>do";
      action  = "<cmd>lua require('dap').step_out()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Step out"; };
    }
    {
      key     = "<leader>dr";
      action  = "<cmd>lua require('dapui').toggle()<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Toggle DAP UI"; };
    }

    # ── Movimentação visual ───────────────────────────────────────────────────
    # Melhorar navegação com hjkl quando as linhas são longas
    {
      key     = "j";
      action  = "gj";
      mode    = [ "n" "v" ];
      options = { silent = true; desc = "Move down visually"; };
    }
    {
      key     = "k";
      action  = "gk";
      mode    = [ "n" "v" ];
      options = { silent = true; desc = "Move up visually"; };
    }

    # ── Fechar quickfix e outros painéis com q ────────────────────────────────
    {
      key     = "q";
      action  = ":close<CR>";
      mode    = [ "n" ];
      options = { silent = true; desc = "Close buffer"; };
    }
  ];

  # ── Autocmds ────────────────────────────────────────────────────────────────
  # Automations que rodam em eventos específicos.
  autoGroups = {
    # Grupo para fechar painéis de ajuda/man com q
    auto_close_panels = { };
    # Grupo para highlight quando yanka
    highlight_yank = { };
    # Grupo para remover espaços em branco no fim de linha ao salvar
    trim_whitespace = { };
  };

  autoCmd = [
    # Fechar quickfix, man, help com q
    {
      event   = "FileType";
      pattern = [ "qf" "help" "man" "lspinfo" ];
      command = "nnoremap <buffer> <silent> q :close<CR>";
    }

    # Highlight ao copiar
    {
      event   = "TextYankPost";
      group   = "highlight_yank";
      command = "lua vim.highlight.on_yank { higroup = 'Visual', timeout = 200 }";
    }

    # Remover espaços em branco ao salvar
    {
      event   = "BufWritePre";
      group   = "trim_whitespace";
      command = "%s/\\s\\+$//e";
    }

    # Desabilitar relativenumber no modo insert e terminal
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
      # Java / Spring Boot
      jdtls = {
        enable  = true;
        package = null;   # usa jdt-language-server do sistema
        settings = {
          java = {
            configuration = {
              runtimes = [
                {
                  name   = "JavaSE-21";
                  path   = "/run/current-system/sw";
                }
              ];
            };
            codeAction = {
              sortMembers = {
                enable = true;
              };
            };
          };
        };
      };

      # C/C++
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

      # Nix
      nil_ls = {
        enable = true;
      };

      # Python
      pyright = {
        enable = true;
      };

      # TypeScript / JavaScript
      ts_ls = {
        enable = true;
      };

      # HTML
      html = {
        enable = true;
      };

      # CSS
      cssls = {
        enable = true;
      };

      # JSON
      jsonls = {
        enable = true;
      };
    };

  };

  # ── Completion ──────────────────────────────────────────────────────────────
  plugins.lspkind = {
    enable = true;
    cmp = {
      enable = true;
      menu = {
        nvim_lsp   = "[LSP]";
        buffer     = "[BUF]";
        path       = "[FILE]";
        luasnip    = "[SNIP]";
      };
    };
  };

  # nvim-cmp com fontes
  plugins.cmp-nvim-lsp = { enable = true; };
  plugins.cmp-buffer     = { enable = true; };
  plugins.cmp-path       = { enable = true; };
  plugins.cmp-luasnip    = { enable = true; };
  plugins.cmp-treesitter = { enable = true; };

  plugins.cmp = {
    enable = true;
    settings = {
      snippet = {
        expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
        '';
      };
      sources = [
        { name = "nvim_lsp"; }
        { name = "buffer"; }
        { name = "path"; }
        { name = "luasnip"; }
      ];
      mapping = {
        "<C-k>"   = "cmp.mapping.select_prev_item()";
        "<C-j>"   = "cmp.mapping.select_next_item()";
        "<C-e>"   = "cmp.mapping.abort()";
        "<CR>"    = "cmp.mapping.confirm({ select = true })";
        "<C-Space>" = "cmp.mapping.complete()";
        "<Tab>"   = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
        "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
      };
    };
  };

  # Snippets via Luasnip
  plugins.luasnip = {
    enable = true;
    settings = {
      enable_autosnippets = true;
    };
  };

  # ── Treesitter ──────────────────────────────────────────────────────────────
  plugins.treesitter = {
    enable     = true;
    settings = {
      ensure_installed = [
        "java" "kotlin" "groovy"
        "c" "cpp"
        "nix"
        "python"
        "javascript" "typescript" "tsx"
        "html" "css"
        "json" "yaml" "toml"
        "markdown" "markdown_inline"
        "bash" "vim" "vimdoc" "lua"
        "gitignore" "dockerfile"
        "cmake"
        "sql"
        "zig"
      ];
      auto_install = true;
      highlight = {
        enable = true;
        additional_vim_regex_highlighting = true;
      };
      indent = {
        enable = true;
      };
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

  # ── UI: Filetree, Statusline, Dashboard ────────────────────────────────────
  plugins.nvim-tree = {
    enable = true;
    settings = {
      view = {
        width  = 35;
        side   = "left";
      };
      renderer = {
        icons = {
          show = {
            file   = true;
            folder = true;
            git    = true;
          };
          glyphs = {
            git = {
              unstaged = "✗";
              staged   = "✓";
              unmerged = "";
              renamed  = "➜";
              untracked = "★";
              deleted  = "⊘";
              ignored  = "◌";
            };
          };
        };
      };
      filters = {
        dotfiles     = false;
        git_ignored  = false;
        custom       = [ ".git" "node_modules" ".direnv" ".result" ];
      };
      git = {
        enable = true;
      };
      diagnostics = {
        enable = true;
        icons = {
          hint    = "󰠠 ";
          info    = " ";
          warning = " ";
          error   = " ";
        };
      };
    };
  };

  plugins.lualine = {
    enable = true;
    settings = {
      theme = "catppuccin";
      sections = {
        lualine_a = [
          {
            __raw = ''
              {
                'mode',
                fmt = function(str)
                  return '▊ ' .. str
                end
              }
            '';
          }
        ];
        lualine_b = [ "branch" "diff" ];
        lualine_c = [
          {
            __raw = ''
              {
                'diagnostics',
                sources = { 'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic' },
                symbols = { error = ' ', warn = ' ', info = ' ', hint = '󰠠 ' },
              }
            '';
          }
          {
            __raw = ''
              {
                'filename',
                path = 1,
                symbols = { modified = '  ', readonly = '  ' },
              }
            '';
          }
        ];
        lualine_x = [
          {
            __raw = ''
              { 'encoding', fmt = string.lower }
            '';
          }
          {
            __raw = ''
              { 'fileformat', icons_enabled = true }
            '';
          }
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
          {
            __raw = ''
              { icon = '  ', desc = 'Recent files', action = 'Telescope oldfiles', key = 'f' }
            '';
          }
          {
            __raw = ''
              { icon = '  ', desc = 'Find files', action = 'Telescope find_files', key = 'o' }
            '';
          }
          {
            __raw = ''
              { icon = '  ', desc = 'Config files', action = 'Telescope find_files search_dirs={config.home.homeDirectory..\"/.config/nvim\"}', key = 'c' }
            '';
          }
          {
            __raw = ''
              { icon = '  ', desc = 'Session', action = 'SessionRestore', key = 's' }
            '';
          }
          {
            __raw = ''
              { icon = '  ', desc = 'Quit', action = 'qa', key = 'q' }
            '';
          }
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
        find_files = {
          hidden = false;
        };
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

  # Ripgrep como provider do telescope
  plugins.telescope-fzf-native = {
    enable = true;
  };

  # ── Which-key ───────────────────────────────────────────────────────────────
  plugins.which-key = {
    enable = true;
    settings = {
      preset = "helix";
      icons = {
        rules = true;
      };
      spec = [
        {
          __raw = ''
            { '<leader>f', group = 'find' }
          '';
        }
        {
          __raw = ''
            { '<leader>g', group = 'git' }
          '';
        }
        {
          __raw = ''
            { '<leader>d', group = 'debug' }
          '';
        }
        {
          __raw = ''
            { '<leader>c', group = 'code' }
          '';
        }
        {
          __raw = ''
            { '<leader>b', group = 'buffer' }
          '';
        }
      ];
    };
  };

  # ── Indent guides ───────────────────────────────────────────────────────────
  plugins.indent-blankline = {
    enable = true;
    settings = {
      scope = {
        enabled = true;
        show_start = false;
      };
      indent = {
        char = "│";
      };
    };
  };

  # ── Comment ─────────────────────────────────────────────────────────────────
  plugins.comment = {
    enable = true;
    settings = {
      toggler = {
        line = "gcc";
        block = "gbc";
      };
      opleader = {
        line = "gc";
        block = "gb";
      };
    };
  };

  # ── Surrounded (vim-surround) ───────────────────────────────────────────────
  plugins.nvim-surround = {
    enable = true;
  };

  # ── Autopairs ───────────────────────────────────────────────────────────────
  plugins.nvim-autopairs = {
    enable = true;
  };

  # ── Todo comments ───────────────────────────────────────────────────────────
  plugins.todo-comments = {
    enable = true;
  };

  # ── DAP (Debug Adapter Protocol) ───────────────────────────────────────────
  plugins.nvim-dap = {
    enable = true;
    settings = {
      adapters = {
        # Java DAP adapter (nvim-jdtls já configura, mas garantimos)
        java = {
          type = "server";
          port = "\${port}";
          executable = {
            command = "java";
            args = [
              "-cp"
              "/run/current-system/sw/share/java/jdt-language-server/plugins/*"
              "com.microsoft.java.debug.plugin.internal.JavaDebugServer"
              "\${port}"
            ];
          };
        };
      };
      signs = {
        dapBreakpoint       = { text = "●"; texthl = "DapBreakpoint"; };
        dapBreakpointCondition = { text = "●"; texthl = "DapBreakpointCondition"; };
        dapLogPoint         = { text = "◆"; texthl = "DapLogPoint"; };
        dapStopped          = { text = "▶"; texthl = "DapStopped"; };
        dapBreakpointRejected = { text = "○"; texthl = "DapBreakpointRejected"; };
      };
    };
  };

  # DAP UI
  plugins.nvim-dap-ui = {
    enable = true;
  };

  # DAP virtual text (mostra variáveis inline)

  # CodeLLDB para C/C++ debugging - configurado via extraConfigLua

  # ── Nix: format via extraConfigLua (nixfmt) ────────────────────────────────

  # ── Floating terminal ──────────────────────────────────────────────────────
  plugins.toggleterm = {
    enable = true;
    settings = {
      direction = "float";
      float_opts = {
        border = "curved";
      };
    };
  };

  # ── Extra Plugins não suportados nativamente ────────────────────────────────
  extraPlugins = with pkgs.vimPlugins; [
    # nvim-web-devicons para ícones no nvim-tree e lualine
    nvim-web-devicons
  ];

  # ── Lua Config (automations e setup que não tem opção Nix) ─────────────────
  # extraConfigLua é injetado no init.lua após os plugins carregarem.
  # Útil para: configurações complexas de DAP, ftplugin, maven-nvim, etc.
  extraConfigLua = ''
    -- ── DAP: Configuração Java ────────────────────────────────────────────────
    -- nvim-jdtls configura DAP automaticamente, mas precisamos do dap adapter
    -- quando o jdtls não está usando nvim-jdtls.
    -- Para uso com nvim-jdtls, o adapter é configurado pelo próprio plugin.

    -- ── DAP: Configuração C/C++ (CodeLLDB) ───────────────────────────────────
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

    -- ── DAP: Configuração Python ──────────────────────────────────────────────
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

    -- ── DAP UI: Posição padrão ───────────────────────────────────────────────
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

    -- Abrir DAP UI automaticamente ao iniciar debugging
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    -- ── LSP: Diagnostics virtuais ────────────────────────────────────────────
    vim.diagnostic.config({
      virtual_text = {
        source = "always",
        spacing = 2,
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- ── Formatação on save ───────────────────────────────────────────────────
    -- Se format_on_save é suportado pelo servidor LSP
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        -- Só formata se o buffer tem LSP com formatting capability
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

    -- ── Highlight on cursor hold ─────────────────────────────────────────────
    vim.api.nvim_create_augroup("CursorHoldHighlight", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = "CursorHoldHighlight",
      pattern = "*",
      callback = function()
        vim.lsp.buf.document_highlight()
      end,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = "CursorHoldHighlight",
      pattern = "*",
      callback = function()
        vim.lsp.buf.clear_references()
      end,
    })

    -- ── Nix: Usar nixfmt para formatar arquivos .nix ────────────────────────
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "nix",
      callback = function()
        vim.bo.formatexpr = "v:lua.vim.lsp.formatexpr(#{timeout_ms=500})"
      end,
    })

    -- ── Melhorias gerais ─────────────────────────────────────────────────────
    -- Fechar buffer com :q
    vim.keymap.set("n", "<leader>x", "<cmd>bd<CR>", { desc = "Delete buffer" })
  '';
}
