{ pkgs, inputs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      ghostty = "GTK_IM_MODULE=simple ghostty";
      cd = "z";
      la = "lazy-click";
    };
    
    history.size = 10000;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "awesomepanda";
    };

    initContent = ''
      eval "$(direnv hook zsh)"
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
}
