{ pkgs, inputs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ls = "eza --color=always --icons=always";
      cat = "bat --color=always";
      cd = "z";
      ghostty = "GTK_IM_MODULE=simple ghostty";
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
}
