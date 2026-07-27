{ config, pkgs, inputs, ... }:

{
  home.username = "livara";
  home.homeDirectory = "/home/livara";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # LSP Servers para Neovim
    clangd
    python3Packages.pyright
    nodePackages.vscode-html-languageserver
    nodePackages.vscode-css-languageserver
    nodePackages.typescript-language-server
    # Ferramentas para Manim (Python)
    python3Packages.manim
    python3Packages.manim-voiceover
    # Outras ferramentas úteis
    ripgrep # para Telescope live_grep
    fd # para Telescope find_files
  ];

  # Neovim focado em Java/Spring Boot pesado e tema GitHub Dark
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
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

    extraConfig = ''
      set number
      set relativenumber
      set termguicolors
      set background=dark
      
      " Tema GitHub Dark adaptando o background ao terminal
      colorscheme github_dark
      highlight Normal guibg=NONE ctermbg=NONE
      highlight NonText guibg=NONE ctermbg=NONE

      lua << EOF
      -- Configuração do LSP para Java (jdtls)
      local lspconfig = require(\'lspconfig\')
      local cmp = require(\'cmp\')

      cmp.setup({
        snippet = {
          expand = function(args)
            require(\'luasnip\').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          [\'<C-b>\'] = cmp.mapping.scroll_docs(-4),
          [\'<C-f>\'] = cmp.mapping.scroll_docs(4),
          [\'<C-Space>\'] = cmp.mapping.complete(),
          [\'<C-e>\'] = cmp.mapping.abort(),
          [\'<CR>\'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = \'nvim_lsp\' },
          { name = \'luasnip\' },
        }, {
          { name = \'buffer\' },
        })
      })

      local capabilities = require(\'cmp_nvim_lsp\').default_capabilities()

      -- Configuração do LSP para Java (jdtls) e nvim-java
      require(\'java\').setup{} -- Inicializa nvim-java
      lspconfig.jdtls.setup{
        capabilities = capabilities,
        cmd = { \'jdtls\' },
        root_dir = function(fname)
          -- Detecta projetos Java/Spring Boot e também um diretório \'Projects\' no home
          local root_patterns = {\"pom.xml\", \"gradle.build\", \".git\"}
          local project_root = require(\'lspconfig.util\').root_pattern(unpack(root_patterns))(fname)
          if project_root then return project_root end

          local home_projects = vim.fn.expand(\'~/Projects\')
          if vim.fn.isdirectory(home_projects) and string.find(fname, home_projects, 1, true) then
            return home_projects
          end
          return vim.fn.getcwd()
        end,
      }

      -- Configuração do nvim-tree
      require(\'nvim-tree\').setup({
        sort_by = \"case_sensitive\",
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
          icons = {
            git_placement = \"before\",
            padding = \" \",
            symlink_arrow = \" ➛ \",
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
            glyphs = {
              default = \"\",
              symlink = \"\",
              folder = {
                arrow_open = \"\",
                arrow_closed = \"\",
                default = \"\",
                open = \"\",
                empty = \"\",
                empty_open = \"\",
                symlink = \"\",
                symlink_open = \"\",
              },
              git = {
                unstaged = \"\",
                staged = \"✓\",
                untracked = \"\",
                renamed = \"➜\",
                unmerged = \"\",
                deleted = \"\",
                ignored = \"◌\",
              },
            },
          },
        },
        filters = {
          dotfiles = true,
        },
        git = {
          enable = true,
          ignore = false,
          timeout = 500,
        },
        actions = {
          open_file = {
            quit_on_open = true,
            resize_window = true,
            window_picker = {
              enable = true,
              chars = \"abcdefghijklmnopqrstuvwxyz\",
              exclude = {
                filetype = { \"NvimTree\", \"packer\", \"qf\", \"help\" },
                buftype = { \"nofile\", \"terminal\", \"prompt\" },
              },
            },
          },
        },
      })

      -- Configuração do lualine
      require(\'lualine\').setup({
        options = {
          icons_enabled = true,
          theme = \'github-dark\',
          component_separators = { left = \'\', right = \'\'},
          section_separators = { left = \'\', right = \'\'},
          globalstatus = true,
        },
        sections = {
          lualine_a = {\'mode\'},
          lualine_b = {\'branch\', \'diff\', \'diagnostics\'},
          lualine_c = {\'filename\'},
          lualine_x = {\'encoding\', \'fileformat\', \'filetype\'},
          lualine_y = {\'progress\'},
          lualine_z = {\'location\'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {\'filename\'},
          lualine_x = {\'location\'},
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {\'nvim-tree\', \'which-key\'}
      })

      -- Configuração do which-key
      require(\'which-key\').setup()

      -- Configuração do gitsigns
      require(\'gitsigns\').setup()

      -- Configuração do bufferline
      require(\'bufferline\').setup()

      -- Configuração do dashboard-nvim
      require(\'dashboard\').setup({
        theme = \'hyper\',
        config = {
          header = {
            \'                                                               \',
            \' █████╗ ███╗   ██╗██╗   ██╗ █████╗ ███╗   ██╗██╗    ██╗\',
            \'██╔══██╗████╗  ██║██║   ██║██╔══██╗████╗  ██║██║    ██║\',
            \'███████║██╔██╗ ██║██║   ██║███████║██╔██╗ ██║██║ █╗ ██║\',
            \'██╔══██║██║╚██╗██║██║   ██║██╔══██║██║╚██╗██║██║███╗██║\',
            \'██║  ██║██║ ╚████║╚██████╔╝██║  ██║██║ ╚████║╚███╔███╝\',
            \'╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚══╝╚══╝ \',
            \'                                                               \',
            \'  A modern, modular, and declarative Neovim configuration.  \',
            \'                                                               \',
          },
          center = {
            {
              icon = \'  \',
              desc = \'Find File\',
              action = \'Telescope find_files\',
              key = \'f\',
            },
            {
              icon = \'  \',
              desc = \'New File\',
              action = \'enew\',
              key = \'n\',
            },
            {
              icon = \'  \',
              desc = \'Recent Files\',
              action = \'Telescope oldfiles\',
              key = \'r\',
            },
            {
              icon = \'  \',
              desc = \'Explore Files\',
              action = \'NvimTreeToggle\',
              key = \'e\',
            },
            {
              icon = \'  \',
              desc = \'Configuration\',
              action = \'e ~/.config/nvim/init.lua\',
              key = \'c\',
            },
            {
              icon = \'  \',
              desc = \'Quit Neovim\',
              action = \'qa\',
              key = \'q\',
            },
          },
          footer = {},
        },
      })

      -- Mapeamentos de teclas
      vim.keymap.set(\'n\', \'<leader>e\', \":NvimTreeToggle<CR>\", { desc = \'Toggle NvimTree\' })
      vim.keymap.set(\'n\', \'<leader>ff\', \'<cmd>Telescope find_files<CR>\', { desc = \'Find Files\' })
      vim.keymap.set(\'n\', \'<leader>fg\', \'<cmd>Telescope live_grep<CR>\', { desc = \'Live Grep\' })
      vim.keymap.set(\'n\', \'<leader>fb\', \'<cmd>Telescope buffers<CR>\', { desc = \'Find Buffers\' })
      vim.keymap.set(\'n\', \'<leader>fh\', \'<cmd>Telescope help_tags<CR>\', { desc = \'Help Tags\' })

      -- Configuração de LSP para outras linguagens
      -- C++
      lspconfig.clangd.setup({
        capabilities = capabilities,
      })

      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })

      -- HTML
      lspconfig.html.setup({
        capabilities = capabilities,
      })

      -- CSS
      lspconfig.cssls.setup({
        capabilities = capabilities,
      })

      -- JavaScript/TypeScript
      lspconfig.tsserver.setup({
        capabilities = capabilities,
      })

      EOF
    '';
  };

  # Alacritty com GitHub Dark, padding e otimizações
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
        dynamic_padding = true;
        decorations = "none";
      };
      font = {
        normal = {
          family = "monospace";
          style = "Regular";
        };
        size = 12.0;
      };
      colors = {
        primary = {
          background = "#0d1117";
          foreground = "#b3b1ad";
        };
        normal = {
          black   = "#484f58";
          red     = "#ff7b72";
          green   = "#3fb950";
          yellow  = "#d29922";
          blue    = "#58a6ff";
          magenta = "#bc8cff";
          cyan    = "#39c5cf";
          white   = "#b1bac4";
        };
        bright = {
          black   = "#6e7681";
          red     = "#ffa198";
          green   = "#56d364";
          yellow  = "#e3b341";
          blue    = "#79c0ff";
          magenta = "#d2a8ff";
          cyan    = "#56d4dd";
          white   = "#f0f6fc";
        };
      };
    };
  };

  # Bash para produtividade (autocomplete)
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  # Associações de arquivos (MIME types)
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

  # Configurar o desktop entry do Neovim para rodar no Alacritty
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "alacritty -e nvim %F";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/x-java" ];
  };

  # XDG User Dirs em inglês
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
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
