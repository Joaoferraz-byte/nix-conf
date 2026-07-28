require("dashboard").setup({
  theme = "hyper",
  config = {
    header = {
      "",
      "",
      "                        LIVARA",
      "",
      "      Neovim declarativo — C/C++ · Java · Kotlin · Angular · Manim",
      "",
    },
    center = {
      { icon = "  ", desc = "Procurar Arquivo", action = "Telescope find_files", key = "f" },
      { icon = "  ", desc = "Novo Arquivo", action = "enew", key = "n" },
      { icon = "  ", desc = "Arquivos Recentes", action = "Telescope oldfiles", key = "r" },
      { icon = "  ", desc = "Explorar Arquivos", action = "NvimTreeToggle", key = "e" },
      { icon = "  ", desc = "Configuração", action = "e ~/.config/nvim/init.lua", key = "c" },
      { icon = "  ", desc = "Sair do Neovim", action = "qa", key = "q" },
    },
  },
})
