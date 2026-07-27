{ config, pkgs, inputs, ... }:

{
  home.username = "livara";
  home.homeDirectory = "/home/livara";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

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
      local lspconfig = require('lspconfig')
      local cmp = require('cmp')

      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        })
      })

      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- O nvim-jdtls precisa de uma configuração específica, geralmente via ftplugin/java.lua
      -- Aqui inicializamos de forma básica para suportar Spring Boot
      lspconfig.jdtls.setup{
        capabilities = capabilities,
        cmd = { 'jdtls' },
        root_dir = function(fname)
          return require('lspconfig.util').root_pattern('pom.xml', 'gradle.build', '.git')(fname) or vim.fn.getcwd()
        end,
      }
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
