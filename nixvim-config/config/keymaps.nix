{ ... }:
{
  globals.mapleader = " ";

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
      event = "FileType";
      pattern = [ "qf" "help" "man" "lspinfo" ];
      command = "nnoremap <buffer> <silent> q :close<CR>";
    }
    {
      event = "TextYankPost";
      group = "highlight_yank";
      command = "lua vim.highlight.on_yank { higroup = 'Visual', timeout = 200 }";
    }
    {
      event = "InsertEnter";
      pattern = "*";
      command = "setlocal norelativenumber";
    }
    {
      event = "InsertLeave";
      pattern = "*";
      command = "setlocal relativenumber";
    }
  ];
}
