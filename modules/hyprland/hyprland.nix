{ config, pkgs, lib, ... }:

{
  home.file.".XCompose".text = ''
    include "%L"
    <dead_acute> <C> : "Ç" Ccedilla
    <dead_acute> <c> : "ç" ccedilla
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # Pin to the classic settings backend; HM's lua codegen for hyprland 0.55
    # is still buggy as of mid-2026. Revisit once that's stable.
    configType = "hyprlang";

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";

      general = {
        border_size = 0;
        "col.active_border" = "rgb(774c81)";
        "col.inactive_border" = "rgb(392A48)";
        # note: sway's per-state colors (background/text/indicator) were
        # titlebar-related; irrelevant here since Hyprland has no titlebars
        # by default and you're not running one.
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          xray = false;
          passes = 2;
          size = 5;
        };
      };

      input = {
        kb_layout = "us";
        kb_variant = "intl";
        kb_options = "caps:escape,escape:none";
      };

      exec-once = [
        "noctalia-shell"
      ];

      bind = [
        "$mod, D, exec, noctalia-shell ipc call launcher toggle"
        "$mod, Return, exec, $terminal"
        "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
        "ALT SHIFT, Q, killactive"
        "ALT, L, exec, noctalia-shell ipc call lockScreen lock"

        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl prev"
      ];

      windowrulev2 = [
        "blur, class:^(com.mitchellh.ghostty)$"
      ];
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
