{ config, pkgs, lib, ... }:

{
  home.file.".XCompose".text = ''
    include "%L"
    <dead_acute> <C> : "Ç" Ccedilla
    <dead_acute> <c> : "ç" ccedilla
  '';

  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.sway;
    extraOptions = [ "--unsupported-gpu" ];

    config = rec {
      modifier = "Mod4";
      terminal = "ghostty";

      window = {
        border = 0;
        titlebar = false;
        hideEdgeBorders = "smart";
      };

      colors = {
        focused = {
          border = "#774c81";
          background = "#774c81";
          text = "#774c81";
          indicator = "#774c81";
          childBorder = "#774c81";
        };
        focusedInactive = {
          border = "#392A48";
          background = "#392A48";
          text = "#392A48";
          indicator = "#392A48";
          childBorder = "#392A48";
        };
        unfocused = {
          border = "#392A48";
          background = "#392A48";
          text = "#392A48";
          indicator = "#392A48";
          childBorder = "#392A48";
        };
        urgent = {
          border = "#2f343a";
          background = "#900000";
          text = "#ffffff";
          indicator = "#900000";
          childBorder = "#900000";
        };
      };

      floating.border = 1;
      # gaps.inner = 8;

      bars = [];

      input = {
        "type:keyboard" = {
          # xkb_layout = "custom";
          xkb_layout = "us";
          xkb_variant = "intl";
          xkb_options = "caps:escape,escape:none"; # remap caps to escape
        };
      };

      # output = {
      #   "HDMI-A-1" = { position = "1920,0"; };
      #   "eDP-1" = { position = "0,0"; };
      # };

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in lib.mkOptionDefault {
        # unset defaults
        "${mod}+e" = null; # layout split 
        "${mod}+w" = null; # layout tabbed
        "${mod}+Shift+q" = null; # kill application
        "${mod}+Shift+e" = null; # exit sway shortcut

        # set custom bindings
        "${mod}+d" = "exec vicinae toggle"; # toggle launcher
        "${mod}+Return" = "exec ${config.wayland.windowManager.sway.config.terminal}"; # open terminal
        "${mod}+Shift+s" = "exec grim -g \"$(slurp)\" - | wl-copy"; # screenshot
        "Mod1+Shift+q" = "kill"; # kill focused app
        "Mod1+l" = "exec qs ipc call session lock"; # lock screen

        # function keys
        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86MonBrightnessUp" = "exec brightnessctl set +10%";
        "XF86MonBrightnessDown" = "exec brightnessctl set 10%-";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl prev";
      };
    };
  };

  home.packages = with pkgs; [
    grim
    slurp
    playerctl
    pulseaudio
    brightnessctl
    wl-clipboard
  ];
}
