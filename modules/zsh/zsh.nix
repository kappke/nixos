{ config, pkgs, inputs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ls = "eza --color=always --icons=always";
      cd = "z";
      ghostty = "GTK_IM_MODULE=simple ghostty";
      claude-work = "CLAUDE_CONFIG_DIR=$HOME/.claude-work claude";
    };
    
    history.size = 10000;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "norm";
    };

    initContent = ''
      eval "$(direnv hook zsh)"
      if [ -f "$HOME/.local/bin/code" ]; then
        source "$HOME/.local/bin/code"
      fi
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # better cd 
  programs.zoxide = {
    enable = true;
  };

  # better ls
  programs.eza = {
    enable = true;
  };

  # better cat
  programs.bat = {
    enable = true;
  };

  # second claude account: separate login, shares memory and skills with ~/.claude
  home.file.".claude-work/projects".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/projects";
  home.file.".claude-work/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/skills";
}
