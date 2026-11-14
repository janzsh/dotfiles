{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # Sin esto home-manager escribe ~/.config/nvim/init.lua y choca con el
    # symlink del directorio entero. Así el init.lua del módulo (desactivar
    # proveedores) se inyecta por el wrapper y ~/.config/nvim queda libre.
    sideloadInitLua = true;
    # Herramientas que lazy.nvim y los plugins esperan en el PATH. Los LSP/
    # formateadores se añaden aquí (no con mason: sus binarios no corren en NixOS).
    extraPackages = with pkgs; [
      # base (lazy, telescope, treesitter)
      git gcc gnumake ripgrep fd tree-sitter
      # image.nvim (previsualizar imágenes en neo-tree)
      imagemagick
      # lua (lua/plugins/lang/lua.lua)
      lua-language-server stylua
      # go (goimports viene en gotools; delve para nvim-dap-go)
      go gopls gotools delve
      # python (lua/plugins/lang/python.lua; debugpy para nvim-dap-python)
      basedpyright ruff python3Packages.debugpy
      # toml
      taplo
      # json (jsonls)
      vscode-langservers-extracted
      # sql (formateo)
      sqlfluff
    ];
  };

  # Enlace directo al repo (como sway/quickshell): editar la config Lua no
  # requiere rebuild, y lazy-lock.json queda escribible dentro del repo.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/home/janz/dotfiles/config/nvim";
}
