{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Core file manager
    thunar
    
    # Thunar plugins (updated paths)
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    
    # Essential for thumbnails and previews
    ffmpegthumbnailer
    tumbler
    
    # Archive support
    file-roller
    p7zip
    unzip
    unrar
    
    # File search
    catfish
    fd
    
    # Media viewers
    mpv
    imv
    gthumb
    
    # GVFS for network/removable media
    gvfs
  ];

  # XDG MIME associations (force overwrite)
  xdg.mimeApps = {
    enable = true;

    associations.added."x-scheme-handler/claude" = [ "com.anthropic.Claude.desktop" ];

    defaultApplications = {
      "inode/directory" = "thunar.desktop";
      
      # Images
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      
      # Videos
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      
      # Audio
      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      
      # Archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      
      # Text
      "text/plain" = "nvim.desktop";

      "x-scheme-handler/claude" = "com.anthropic.Claude.desktop";
    };
  };

  xdg.configFile."mimeapps.list".force = true;

  # Enable Thunar as default file manager
  xdg.configFile."xfce4/helpers.rc".text = ''
    FileManager=Thunar
  '';

  # GTK settings for better file picker integration
  gtk = {
    enable = true;
    
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    gtk4.theme = config.gtk.theme;
    
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
    
    font = {
      name = "Inter";
      size = 11;
      package = pkgs.inter;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk3.bookmarks = [
      "file://${config.home.homeDirectory}/Documents"
      "file://${config.home.homeDirectory}/Downloads"
      "file://${config.home.homeDirectory}/Pictures"
      "file://${config.home.homeDirectory}/Videos"
    ];
  };
}
