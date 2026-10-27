{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    ripgrep
    tree-sitter
    prettierd
    typescript # 7.x ships the native Go tsc, used as LSP via `tsc --lsp`
    black
    lua
    python3
    luajitPackages.luarocks_bootstrap
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withPython3 = true;
  };

  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}
