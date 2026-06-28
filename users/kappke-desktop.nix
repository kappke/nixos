{ config, pkgs, inputs, ... }:

{
  imports = [
    ./common.nix
    ../modules/thunar/thunar.nix
    ../modules/zen-browser/zen-browser.nix
    ../modules/x11/i3.nix
    ../modules/nvim/nvim.nix
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
    NIXOS_OZONE_WL = "0";
    GTK_IM_MODULE = "cedilla";
    QT_IM_MODULE = "cedilla";
  };

  home.file.".profile".text = ''
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share
  '';
}
