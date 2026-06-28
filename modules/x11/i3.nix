{ config, pkgs, lib, ... }:

{
  home.file.".XCompose".text = ''
    include "%L"
    <dead_acute> <C> : "Ç" Ccedilla
    <dead_acute> <c> : "ç" ccedilla
  '';

  xsession.enable = true;

  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3;

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
          text = "#ffffff";
          indicator = "#774c81";
          childBorder = "#774c81";
        };
        focusedInactive = {
          border = "#392A48";
          background = "#392A48";
          text = "#888888";
          indicator = "#392A48";
          childBorder = "#392A48";
        };
        unfocused = {
          border = "#392A48";
          background = "#392A48";
          text = "#888888";
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
      gaps.inner = 8;

      bars = [];

      keybindings = let
        mod = config.xsession.windowManager.i3.config.modifier;
      in lib.mkOptionDefault {
        # unset defaults that conflict with custom bindings
        "${mod}+e" = null;
        "${mod}+w" = null;
        "${mod}+Shift+q" = null;
        "${mod}+Shift+e" = null;

        # set custom bindings
        "${mod}+d" = "exec rofi -show drun";
        "${mod}+Return" = "exec ${config.xsession.windowManager.i3.config.terminal}";
        "${mod}+Shift+s" = "exec maim -s | xclip -selection clipboard -t image/png";
        "Mod1+Shift+q" = "kill";
        "Mod1+l" = "exec loginctl lock-session";

        # function keys
        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl prev";
      };
    };

    extraConfig = ''
      smart_gaps on
    '';
  };

  home.packages = with pkgs; [
    maim
    xclip
    playerctl
    pulseaudio
    rofi
    i3lock
  ];
}