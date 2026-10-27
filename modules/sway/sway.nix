{ config, pkgs, lib, ... }:

let
  flameshot = pkgs.flameshot.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/utils/screengrabber.cpp \
        --replace-fail '#include <QApplication>' '#include <QApplication>
      #include <QJsonArray>
      #include <QJsonDocument>
      #include <QJsonObject>' \
        --replace-fail '    // Capture Active Monitor: auto-select monitor under cursor' '    // Ask Sway before opening any UI, while the original output is focused.
          if (m_info.waylandDetected() && qEnvironmentVariableIsSet("SWAYSOCK")) {
              QProcess sway;
              sway.start("${pkgs.sway}/bin/swaymsg", { "-t", "get_outputs", "-r" });
              if (sway.waitForFinished(3000) && sway.exitCode() == 0) {
                  const auto outputs = QJsonDocument::fromJson(sway.readAllStandardOutput()).array();
                  for (const auto& output : outputs) {
                      const auto object = output.toObject();
                      if (!object.value("focused").toBool()) {
                          continue;
                      }
                      for (int i = 0; i < screens.size(); ++i) {
                          if (screens[i]->name() == object.value("name").toString()) {
                              m_selectedMonitor = i;
                              return cropToMonitor(fullScreenshot, i);
                          }
                      }
                  }
              }
          }

          // Capture Active Monitor: auto-select monitor under cursor' \
        --replace-fail 'int minX = 0, minY = 0;' 'int minX = screens.first()->geometry().x(), minY = screens.first()->geometry().y();'
    '';
  });
in
{
  services.flameshot = {
    enable = true;
    package = flameshot;
  };

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
      window.commands = [
        {
          criteria.app_id = "^(org\\.flameshot\\.Flameshot|flameshot)$";
          command = "floating enable, border none, fullscreen enable";
        }
      ];
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
        "${mod}+Shift+s" = "exec ${flameshot}/bin/flameshot gui"; # screenshot
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
