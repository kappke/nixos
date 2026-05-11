{ config, inputs, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  # Bootloader (systemd EFI version)
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  
  # Bootloader (GRUB version)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = false;

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
    mutableSettings = false;
    settings = {
      dns = {
        upstream_dns = [
          "https://dns10.quad9.net/dns-query"
          "1.1.1.1"
          "8.8.8.8"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
          "8.8.8.8"
        ];
        bind_hosts = [ "0.0.0.0" ];
        rewrites = [
          {
            domain = "dash.server";
            answer = "192.168.100.73";
          }
          {
            domain = "adguard.server";
            answer = "192.168.100.73";
          }
        ];
      };
      filtering = {
        enabled = true;
        interval = 24;
      };
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
      ];
    };
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true; # Opens port 8082 by default
    # allowedHosts = "server,server.walrus-ruffe.ts.net,192.168.100.17,localhost";
    allowedHosts = "*";
    
    # These settings define the layout dashboard
    services = [
      {
        "Infrastructure" = [
          {
            "AdGuard Home" = {
              icon = "adguard-home.png";
              href = "http://server:3000"; # Access via MagicDNS
              description = "Network-wide Adblocking";
              widget = {
                type = "adguard";
                url = "http://localhost:3000";
                username = "admin"; 
                password = "admin"; 
              };
            };
          }
        ];
      }
      {
        "Network" = [
          {
            "Tailscale" = {
              icon = "tailscale.png";
              href = "https://login.tailscale.com/admin/machines";
              description = "Mesh VPN Status";
            };
          }
        ];
      }
      {
        "Storage" = [
          {
            "FileBrowser" = {
              icon = "filebrowser.png";
              href = "http://server:8080"; # Replace with your Tailscale IP
              description = "Family Photos & Documents";
              widget = {
                type = "filebrowser";
                url = "http://127.0.0.1:8080"; # Use localhost since it's on the same machine
                key = "";  # FileBrowser uses the password as the 'key'
              };
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          format = {
            timeStyle = "short";
            dateStyle = "short";
          };
        };
      }
    ];
  };

  services.filebrowser = {
    enable = true;
    settings = {
      port = 8080;
      address = "0.0.0.0"; # Listen on all interfaces so Tailscale can reach it
      root = "/mnt/family-files";
    };
  };

  # Ensure the service can read the mount point
  systemd.services.filebrowser.serviceConfig.ProtectHome = "read-only";

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    
    virtualHosts = {
      "filebrowser.server" = {
        locations."/".proxyPass = "http://127.0.0.1:8080";
      };
      "dash.server" = {
        locations."/".proxyPass = "http://127.0.0.1:8082";
      };
      "adguard.server" = {
        locations."/".proxyPass = "http://127.0.0.1:3000";
      };
    };
  };

  # Keep it running when lid is closed
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
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ 
      "root"
      "kappke"
      "@wheel"
    ];
  };

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

  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024;
    }
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}
