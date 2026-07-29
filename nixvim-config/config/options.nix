{ ... }:
{
  # ── Vim Options ─────────────────────────────────────────────────────────────
  opts = {
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
    cursorline = true;
    mouse = "a";
    splitbelow = true;
    splitright = true;
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
      enable = true;
      nvimRuntime = true;
      configs = true;
      plugins = true;
    };
  };
}
