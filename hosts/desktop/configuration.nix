# /etc/nixos/configuration.nix

{ config, inputs, pkgs, ... }:

let
  wallpaper = pkgs.copyPathToStore ./wallpapers/wallhaven-6llkol.png;

  gtkgreetCSS = pkgs.writeText "gtkgreet.css" ''
    window {
      background-color: transparent;
    }
  '';

  swayConfig = pkgs.writeText "greetd-sway-config" ''
    output * bg ${wallpaper} fill

    exec "${pkgs.gtkgreet}/bin/gtkgreet -l -s ${gtkgreetCSS}; swaymsg exit"

    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway --config ${swayConfig}";
      };
      initial_session = {
        command = "sway";
        user = "kappke";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
    bash
  '';


  imports =
    [ 
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    plymouth = {
      enable = true;
      theme = "rings";  # or "bgrt" for OEM logo
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };

    # Silent boot configuration
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "uinput" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "kappke-desktop"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.firewall.trustedInterfaces = [ "docker0" ];
  networking.firewall.allowedTCPPorts = [ 22 8080 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; 
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.seahorse.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  services.tailscale = {
    enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
    LC_CTYPE = "pt_BR.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [];
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  security.polkit.enable = true;
  programs.zsh.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kappke = {
    isNormalUser = true;
    description = "Vinícius Kappke";
    extraGroups = [ "networkmanager" "wheel" "video" "render" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "kappke" = import ../../users/kappke.nix;
    };
  };

  virtualisation.docker = {
    enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # programming
    go
    bun
    nodejs
    gcc
    cmake
    gnumake

    # utilities
    wget
    zip
    unzip
    tree

    # apps
    btop # process monitor
    oxker # docker TUI
    kitty # terminal emulator
    ghostty # terminal emulator
    github-cli

    # gaming
    heroic
    mangohud
  ];

  fonts.packages = with pkgs; [
    # ui
    roboto
    roboto-slab
    roboto-mono
    roboto-serif
    fira-code
    fira-code-symbols
    # nerdfonts
  ];

  system.stateVersion = "25.11"; # Did you read the comment?

  swapDevices = [
    {
      device = "/swapfile";
      size = 32 * 1024;
    }
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}