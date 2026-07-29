{ ... }:
{
  imports = [
    ./ui.nix
    ./lsp.nix
    ./dap.nix
  ];

  plugins = {
    web-devicons.enable = true;
    gitsigns.enable = true;
    trim.enable = true;
    todo-comments.enable = true;
    comment.enable = true;
    leap.enable = true;
    undotree.enable = true;
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        indent.enable = true;
        highlight.enable = true;
      };
    };
  };
}
