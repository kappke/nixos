{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    ripgrep
    tree-sitter
    prettierd
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
  };

  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}
