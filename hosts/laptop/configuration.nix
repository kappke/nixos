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

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

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

    # Optional: hide bootloader menu
    # loader.timeout = 0;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.hostName = "kappke"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "docker0" ];
  networking.firewall.allowedTCPPorts = [ 8080 ];

  hardware.bluetooth.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.seahorse.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;

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
  programs.light.enable = true;
  programs.zsh.enable = true;
  programs.steam.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kappke = {
    isNormalUser = true;
    description = "Vinícius Kappke";
    extraGroups = [ "networkmanager" "wheel" "video" ];
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
    fastfetch # sys info tool
    github-cli
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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
