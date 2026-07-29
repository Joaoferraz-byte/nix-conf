{ pkgs, ... }:
{
  plugins = {
    dap = {
      enable = true;
      extensions = {
        dap-ui.enable = true;
        dap-virtual-text.enable = true;
      };
      adapters = {
        executables = {
          # Corrigindo o erro do vscode-codelldb usando o binário direto do pacote
          lldb = {
            command = "${pkgs.lldb}/bin/lldb-dap";
          };
          gdb = {
            command = "gdb";
            args = [ "-i" "dap" ];
          };
        };
      };
      configurations = {
        cpp = [
          {
            name = "Launch (LLDB)";
            type = "lldb";
            request = "launch";
            program = ''
              function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
              end
            '';
            cwd = "\${workspaceFolder}";
            stopOnEntry = false;
          }
        ];
        c = [
          {
            name = "Launch (GDB)";
            type = "gdb";
            request = "launch";
            program = ''
              function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
              end
            '';
            cwd = "\${workspaceFolder}";
          }
        ];
        java = [
          {
            type = "java";
            request = "launch";
            name = "Debug (Attach) - Remote";
            hostName = "127.0.0.1";
            port = 5005;
          }
        ];
      };
    };
  };

  # Garantir que os debuggers estejam instalados
  extraPackages = with pkgs; [
    lldb
    gdb
    vscode-extensions.vadimcn.vscode-lldb
  ];
}
