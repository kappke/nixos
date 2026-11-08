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
      http.address = "0.0.0.0:3001"; # 3000 is taken by the Dokploy panel
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
      };
      filtering = {
        enabled = true;
        interval = 24;
        rewrites = [
          {
            enabled = true;
            domain = "*.home.kappke.dev";
            answer = "100.103.105.88";
          }
        ];
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

  # Docker + Dokploy (swarm). Traefik (80/443) replaces the old nginx.
  virtualisation.docker = {
    enable = true;
    daemon.settings.live-restore = false; # required for swarm
  };

  services.dokploy = {
    enable = true;
    # Image: stable tag pinned by the module (override with `image` if needed)
    database.passwordFile = "/var/lib/secrets/dokploy-db-password";
    auth.secretFile = "/var/lib/secrets/dokploy-auth-secret";
    encryption.keyFile = "/var/lib/secrets/dokploy-encryption-key";
    # Single node: recreate the swarm if the LAN IP changes (DHCP)
    swarm.autoRecreate = true;
    # Cloudflare token for Traefik DNS-01 (root-only env file, not in the store):
    #   CF_DNS_API_TOKEN=...
    traefik.extraArgs = [ "--env-file=/var/lib/secrets/traefik-cloudflare.env" ]; # one token per item (each is shell-escaped)
    # Panel is served by Traefik (dokploy.home.kappke.dev); close direct access.
    port = null;
  };

  # Panel domain, declared here because the UI's "Server Domain" form fails with
  # nix-dokploy: the swarm service is `dokploy_dokploy`, the UI looks for `dokploy`.
  services.dokploy.traefik.dynamicConfig."dokploy-panel" = {
    http.routers.dokploy-panel = {
      rule = "Host(`dokploy.home.kappke.dev`)";
      entryPoints = [ "websecure" ];
      service = "dokploy-panel";
      tls.certResolver = "letsencrypt";
    };
    http.services.dokploy-panel.loadBalancer.servers = [
      { url = "http://dokploy:3000"; }
    ];
  };

  # AdGuard UI (native service on the host) behind Traefik.
  services.dokploy.traefik.dynamicConfig."adguard" = {
    http.routers.adguard = {
      rule = "Host(`adguard.home.kappke.dev`)";
      entryPoints = [ "websecure" ];
      service = "adguard";
      tls.certResolver = "letsencrypt";
    };
    http.services.adguard.loadBalancer.servers = [
      { url = "http://100.103.105.88:3001"; } # host's Tailscale IP, reachable from the Traefik container
    ];
  };

  # Traefik needs 80/443 (Docker bypasses this firewall, kept for documentation)
  networking.firewall.allowedTCPPorts = [ 80 443 ];

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
