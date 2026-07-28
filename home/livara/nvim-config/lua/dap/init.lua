local dap = require("dap")
local dapui = require("dapui")

dapui.setup()
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- Configuração para C/C++ (cpptools ou lldb-dap)
-- É necessário ter o adaptador de debug instalado via Nix
-- Exemplo para cpptools (requer vscode-cpptools)
-- dap.adapters.cpptools = {
--   type = "server",
--   executable = {
--     command = "node",
--     args = { "${pkgs.vscode-cpptools}/extension/debugAdapters/bin/OpenDebugAD7" },
--   },
-- }

-- dap.configurations.cpp = {
--   {
--     name = "Launch file",
--     type = "cpptools",
--     request = "launch",
--     program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/a.out", "file") end,
--     cwd = "${workspaceFolder}",
--     stopOnEntry = true,
--   },
-- }

-- Configuração para Python (debugpy)
-- dap.adapters.python = {
--   type = "executable",
--   command = "python",
--   args = { "-m", "debugpy.adapter" },
-- }

-- dap.configurations.python = {
--   {
--     type = "python",
--     request = "launch",
--     name = "Launch file",
--     program = "${file}",
--     pythonPath = function() return "python" end,
--   },
-- }
