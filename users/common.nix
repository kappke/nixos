{ config, pkgs, ... }:

{
  home.username = "kappke";
  home.homeDirectory = "/home/kappke";

  home.stateVersion = "25.11"; 

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Vinícius Kappke";
        email = "vinikappke@gmail.com";
        signingkey = "~/.ssh/id_ed25519.pub";
      };

      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };

      commit.gpgsign = true;
      push.autoSetupRemote = true;
      init.defaultBranch = "master";
    };
  };

  imports = [
    ../modules/zsh/zsh.nix
    ../modules/nvim/nvim.nix
    ../modules/tmux/tmux.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    gemini-cli
    wget
    zip
    unzip
    tree
    btop
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/bin/xdg-bin"
    "$HOME/.cargo/bin"
    "$HOME/.nix-profile/bin"
    "$HOME/.nix-profile/sbin"
    "$HOME/.config"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
