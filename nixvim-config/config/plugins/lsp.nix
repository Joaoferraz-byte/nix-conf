{ pkgs, ... }:
{
  plugins = {
    lsp = {
      enable = true;
      servers = {
        # Java com JDTLS otimizado
        jdtls = {
          enable = true;
          cmd = [
            "${pkgs.jdt-language-server}/bin/jdtls"
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
              format = {
                enable = true;
                settings = { profile = "GoogleStyle"; };
              };
            };
          };
        };

        # C/C++ com Clangd
        clangd = {
          enable = true;
          cmd = [
            "${pkgs.clang-tools}/bin/clangd"
            "--background-index"
            "--clang-tidy"
            "--header-insertion=iwyu"
            "--completion-style=detailed"
            "--function-arg-placeholders"
          ];
        };

        nil-ls.enable = true;
        pyright.enable = true;
        ts-ls.enable = true;
        html.enable = true;
        cssls.enable = true;
        jsonls.enable = true;
      };
    };

    # Autocompletar centralizado
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        sources = [
          { name = "nvim_lsp"; }
          { name = "buffer"; }
          { name = "path"; }
          { name = "luasnip"; }
          { name = "treesitter"; }
        ];
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif require('luasnip').expand_or_jumpable() then
                require('luasnip').expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" })
          '';
          "<S-Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif require('luasnip').jumpable(-1) then
                require('luasnip').jump(-1)
              else
                fallback()
              end
            end, { "i", "s" })
          '';
        };
      };
    };

    lspkind = {
      enable = true;
      cmp.enable = true;
    };

    luasnip.enable = true;
  };

  # Plugins extras para Java empresarial
  extraPlugins = with pkgs.vimPlugins; [
    nvim-jdtls
  ];
}
