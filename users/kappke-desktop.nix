{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./common.nix
    ../modules/sway/sway.nix
    ../modules/quickshell/desktop-shell.nix
    ../modules/thunar/thunar.nix
    ../modules/zen-browser/zen-browser.nix
    ../modules/octapus-db/octapus-db.nix
    ../modules/nvim/nvim.nix
    ../modules/distrobox/distrobox.nix
  ];

  # Use the NVIDIA-compatible wrapper installed by the NixOS Sway module.
  wayland.windowManager.sway.package = lib.mkForce null;
  wayland.windowManager.sway.config.output."DP-2" = {
    mode = "2560x1080@74.991Hz";
    adaptive_sync = "on";
  };

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

  home.file."Pictures/Wallpapers".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos-config/hosts/desktop/wallpapers"
  );

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher daemon";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server --replace";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "sway-session.target" ];
  };

  services.flameshot = {
    enable = true;
    settings = {
      General = {
          
        # More settings may be found on the Flameshot Github

        # Save Path
        # savePath = "/home/user/Screenshots";
        # Tray
        disabledTrayIcon = true;
        # Greeting message   
        showStartupLaunchMessage = false;
        # Default file extension for screenshots (.png by default)
        saveAsFileExtension = ".png";
        # Desktop notifications
        showDesktopNotification = true;
        # Notification for cancelled screenshot
        showAbortNotification = false;
        # Whether to show the info panel in the center in GUI mode
        showHelp = true;
        # Whether to show the left side button in GUI mode
        showSidePanelButton = true;
        # Whether to enable legacy (pre-xdg-desktop-portal) screenshotting on X11
        useX11LegacyScreenshot = true;
        # Whether to skip display selection prompt (X11-only)
        captureActiveMonitor = true;


        # Color Customization
        uiColor = "#740096";
        contrastUiColor = "#270032";
        drawColor = "#ff0000";

        # For Wayland (Install Grim seperately)
        # useGrimAdapter = true;
        # Stops warnings for using Grim
        # disabledGrimWarning = true;
      };
    };
  };
}
