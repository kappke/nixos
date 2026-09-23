{ config, pkgs, ... }:

let
  giphySearch = pkgs.writeScriptBin "giphy-search" (
    "#!${pkgs.python3}/bin/python3\n" + builtins.readFile ./giphy-search.py
  );
  chatgptUsage = pkgs.writeScriptBin "chatgpt-usage" (
    "#!${pkgs.python3}/bin/python3\n" + builtins.readFile ./chatgpt-usage.py
  );
  restoreWallpaper = pkgs.writeShellScript "restore-desktop-wallpaper" ''
    stateFile="${config.home.homeDirectory}/.config/quickshell/wallpaper-state"
    defaultWallpaper="${config.home.homeDirectory}/Pictures/Wallpapers/wallhaven-6llkol.png"

    if [ -r "$stateFile" ]; then
      IFS= read -r wallpaper < "$stateFile"
      if [ -f "$wallpaper" ]; then
        exec "${pkgs.awww}/bin/awww" img "$wallpaper"
      fi
    fi

    exec "${pkgs.awww}/bin/awww" img "$defaultWallpaper"
  '';
in
{
  fonts.fontconfig.enable = true;

  home.packages = [
    pkgs.quickshell
    pkgs.inter
    pkgs.nerd-fonts.symbols-only
    pkgs.curl
    pkgs.gcalcli
    pkgs.awww
    pkgs.wl-clipboard
    giphySearch
    chatgptUsage
  ];

  home.file.".config/quickshell/desktop-shell".source = ./desktop-shell;
  # Keep wallpaper files outside the Nix store so new images do not require a rebuild.
  home.file."Pictures/Wallpapers".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/projects/nixos-config/hosts/laptop/wallpapers";

  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "Wallpaper daemon";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      ExecStartPost = restoreWallpaper;
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };

  systemd.user.services.quickshell-desktop-shell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell --config desktop-shell";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "XDG_CONFIG_HOME=%h/.config"
        "QT_PLUGIN_PATH=${pkgs.qt6.qtimageformats}/lib/qt-6/plugins"
      ];
    };

    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
