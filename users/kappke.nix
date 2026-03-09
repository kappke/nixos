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

  programs.ghostty = {
    enable = true;
    settings = {
      background = "#1E1E1E";
      background-opacity = 0.75;
      background-blur-radius = 20;
    };
  };

  imports = [
    ../modules/zsh/zsh.nix
    ../modules/sway/sway.nix
    ../modules/nvim/nvim.nix
    ../modules/tmux/tmux.nix
    ../modules/thunar/thunar.nix
    ../modules/noctalia/noctalia.nix
    ../modules/zen-browser/zen-browser.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    spotify
    tableplus
    bruno
    discord
    ani-cli
    (pkgs.slack.overrideAttrs (oldAttrs: {
      installPhase = oldAttrs.installPhase + ''
        wrapProgram $out/bin/slack \
          --set NIXOS_OZONE_WL 0 \
          --add-flags "--ozone-platform=x11"
      '';
    }))
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
    GTK_IM_MODULE = "cedilla";
    QT_IM_MODULE = "cedilla";
  };

  home.file.".profile".text = ''
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share
  '';

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/bin/xdg-bin"
    "$HOME/.cargo/bin"
    "$HOME/.nix-profile/bin"
    "$HOME/.nix-profile/sbin"
    "$HOME/.config"
  ];

  # User targeted configuration
  wayland.windowManager.sway = {
    config = {
      startup = [
        { command = "swaymsg 'workspace 1; workspace 4; workspace 5; workspace 1'"; }
        { command = "zen"; }
        { command = "slack"; }
        { command = "spotify"; }
      ];

      workspaceOutputAssign = [
        { workspace = "1"; output = "HDMI-A-1"; }
        { workspace = "2"; output = "HDMI-A-1"; }
        { workspace = "3"; output = "HDMI-A-1"; }
        { workspace = "4"; output = "eDP-1"; }
        { workspace = "5"; output = "eDP-1"; }
        { workspace = "6"; output = "eDP-1"; } 
      ];

      assigns = {
        "1" =  [{ app_id = "^Zen$"; }];
        "4" =  [{ app_id = "^Slack$"; }];
        "5" =  [{ class = "^Spotify$"; }];
      };
    };

    extraConfig = ''
      set $mod Mod4

      bindsym $mod+q workspace number 4
      bindsym $mod+w workspace number 5
      bindsym $mod+e workspace number 6
      
      bindsym $mod+Shift+q move container to workspace number 4
      bindsym $mod+Shift+w move container to workspace number 5
      bindsym $mod+Shift+e move container to workspace number 6
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
