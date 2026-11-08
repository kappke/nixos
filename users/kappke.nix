{ config, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../modules/sway/sway.nix
    ../modules/hyprland/hyprland.nix
    ../modules/quickshell/desktop-shell.nix
    ../modules/thunar/thunar.nix
    ../modules/zen-browser/zen-browser.nix
    ../modules/octapus-db/octapus-db.nix
    ../modules/distrobox/distrobox.nix
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

  home.packages = with pkgs; [
    vicinae
    inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default
    discord
    ani-cli
    feedr
    prismlauncher
    ngrok
    live-server
    mosh
    tokei
    zenity

    # work related 
    bruno
    # rustdesk
    posting
    lazygit
    claude-code
    codex
    tableplus
    lazydocker
    # redisinsight
    google-cloud-sdk
    (mongodb-compass.overrideAttrs (oldAttrs: {
      buildCommand = builtins.replaceStrings
        [ "wrapGAppsHook $out/bin/mongodb-compass" ]
        [ ":" ]
        oldAttrs.buildCommand;
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
        { command = "vicinae server"; }
        { command = "zen"; }
        { command = "slack"; }
        { command = "spotifast"; }
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
        "5" =  [{ app_id = "^spotifast$"; }];
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

  # Monitors are handled by kanshi, same as under Sway. Hyprland does not export the session
  # environment to systemd, so kanshi.service dies with "failed to connect to display" until
  # WAYLAND_DISPLAY is imported and the start-limit it already burned through is cleared.
  hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user reset-failed kanshi; systemctl --user restart kanshi")
    end)

    for _, rule in ipairs({
        { "1", "HDMI-A-1" }, { "2", "HDMI-A-1" }, { "3", "HDMI-A-1" },
        { "4", "eDP-1" }, { "5", "eDP-1" }, { "6", "eDP-1" },
    }) do
        hl.workspace_rule({ workspace = rule[1], monitor = rule[2] })
    end

    hl.window_rule({ match = { class = "^[Zz]en" }, workspace = "1 silent" })
    hl.window_rule({ match = { class = "^Slack$" }, workspace = "4 silent" })
    hl.window_rule({ match = { class = "^spotifast$" }, workspace = "5 silent" })

    hl.on("hyprland.start", function()
        hl.exec_cmd("zen")
        hl.exec_cmd("slack")
        hl.exec_cmd("spotifast")
    end)

    for key, workspace in pairs({ Q = 4, W = 5, E = 6 }) do
        hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
        hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
    end
  '';

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile = {
          name = "undocked";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1080@60.008Hz";
            }
          ];
        };
      }
      {
        profile = {
          name = "office";
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
      }
      {
        profile = {
          name = "office_alternate";
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
      }
      {
        profile = {
          name = "home";
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
      }
    ];
  };
}
