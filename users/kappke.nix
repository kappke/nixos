{ config, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../modules/sway/sway.nix
    ../modules/thunar/thunar.nix
    ../modules/noctalia/noctalia.nix
    ../modules/zen-browser/zen-browser.nix
  ];

  programs.ghostty = {
    enable = true;
    settings = {
      window-padding-x = 8;
      window-padding-y = 8;
      background = "#0a0a0a";
      foreground = "#e6e8ee";
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      font_size = 12.0;
      font_family = "Fira Code";
      background = "#0a0a0a";
      foreground = "#e6e8ee";
      cursor_trail = 1;
      enable_audio_bell = false;
    };
  };

  home.packages = with pkgs; [
    spotify
    discord
    ani-cli
    prismlauncher
    ngrok
    live-server
    mosh

    # work related 
    bruno
    posting
    opencode
    gemini-cli
    tableplus
    redisinsight
    (mongodb-compass.overrideAttrs (oldAttrs: {
      installPhase = oldAttrs.installPhase + ''
        wrapProgram $out/bin/mongodb-compass \
          --add-flags "--password-store=gnome-libsecret --ignore-additional-command-line-flags"
      '';
    }))
    (slack.overrideAttrs (oldAttrs: {
      installPhase = oldAttrs.installPhase + ''
        wrapProgram $out/bin/slack \
          --set NIXOS_OZONE_WL 0 \
          --add-flags "--ozone-platform=x11"
      '';
    }))
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix for invisible cursor on NVIDIA Wayland
    GTK_IM_MODULE = "cedilla";
    QT_IM_MODULE = "cedilla";
  };

  home.file.".profile".text = ''
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share
  '';

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

  services.kanshi = {
    enable = true;
    profiles = {
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            mode = "1920x1080@60.008Hz";
          }
        ];
      };
      office = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Samsung Electric Company LF24T35 HX5XA07221";
            mode = "1920x1080@74.973Hz";
          }
        ];
      };
      office_alternate = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Samsung Electric Company LF24T35 HX5X609064";
            mode = "1920x1080@74.973Hz";
          }
        ];
      };
      home = {
        outputs = [
          {
            criteria = "eDP-1";
            mode = "1920x1080@60.008Hz";
          }
          {
            criteria = "LG Electronics LG ULTRAWIDE 0x01010101";
            mode = "2560x1080@74.991Hz";
          }
        ];
      };
    };
  };
}
