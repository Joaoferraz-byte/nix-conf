local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Configuração para Java (JDTLS via nvim-java)
require("java").setup({
  lombok = { enable = true },
  java_test = { enable = true },
  java_debug_adapter = { enable = true },
  spring_boot_tools = { enable = true }, -- Suporte a Spring Boot
  jdk = { auto_install = false },
})

-- Função para determinar o diretório raiz do projeto Java
local jdtls_root_dir = function(fname)
  local root_patterns = {"pom.xml", "build.gradle", ".git"}
  local project_root = require("lspconfig.util").root_pattern(unpack(root_patterns))(fname)
  if project_root then return project_root end

  local home_projects = vim.fn.expand("~/Projects")
  if vim.fn.isdirectory(home_projects) and string.find(fname, home_projects, 1, true) then
    return home_projects
  end
  return vim.fn.getcwd()
end

lspconfig.jdtls.setup({
  capabilities = capabilities,
  root_dir = jdtls_root_dir,
})

-- Configuração para C/C++ (Clangd)
lspconfig.clangd.setup({
  capabilities = capabilities,
  -- Adicione aqui configurações específicas do clangd, se necessário
  -- Ex: cmd = { "clangd", "--background-index", "--clang-tidy" },
})

-- Configuração para Python (Pyright)
lspconfig.pyright.setup({
  capabilities = capabilities,
  -- Adicione aqui configurações específicas do pyright, se necessário
})

-- Configuração para Angular (angularls)
lspconfig.angularls.setup({
  capabilities = capabilities,
  -- Adicione aqui configurações específicas do angularls, se necessário
})

-- Configuração para Tailwind CSS
lspconfig.tailwindcss.setup({
  capabilities = capabilities,
  -- Adicione aqui configurações específicas do tailwindcss, se necessário
})

-- Configurações gerais de Web
lspconfig.html.setup({ capabilities = capabilities })
lspconfig.cssls.setup({ capabilities = capabilities })
lspconfig.ts_ls.setup({ capabilities = capabilities })

-- Configuração para Kotlin
lspconfig.kotlin_language_server.setup({ capabilities = capabilities })
