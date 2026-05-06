{ config, inputs, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "server";
  networking.networkmanager.enable = true;

  # Remote Access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # Set to false if you add an SSH key
      PermitRootLogin = "no";
    };
  };
  programs.mosh.enable = true;

  # VPN
  services.tailscale.enable = true;

  # AdGuard Home
  services.adguardhome = {
    enable = true;
    openFirewall = true;
    settings = {
      dns = {
        upstream_dns = [
          "https://dns10.quad9.net/dns-query"
          "1.1.1.1"
          "8.8.8.8"
        ];
      };
      filtering = {
        enabled = true;
      };
    };
  };

  # Old Laptop: Keep it running when lid is closed
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # Time zone and locale (copied from laptop)
  time.timeZone = "America/Sao_Paulo";
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

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # User account
  programs.zsh.enable = true;
  users.users.kappke = {
    isNormalUser = true;
    description = "Vinícius Kappke";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "kappke" = import ../../users/server.nix;
    };
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}
