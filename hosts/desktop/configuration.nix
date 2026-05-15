{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "uinput" ];

  nixpkgs.config.allowUnfree = true;

  # --- Remote Management & Flakes ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ 
      "root"
      "kappke"
      "@wheel"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  networking.hostName = "gaming-node";
  networking.networkmanager.enable = true;
  networking.interfaces.enp5s0.wakeOnLan.enable = true; 

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; 
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  swapDevices = [ { device = "/var/lib/swapfile"; size = 8192; } ];
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true; 
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;

  programs.zsh.enable = true;
  users.users.kappke = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "render" ];
  };

  # Automatic login is required for Sunshine to capture the desktop
  services.displayManager.autoLogin = {
    enable = true;
    user = "kappke";
  };

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.desktopManager.gnome.enable = true;

  # Keyring for password management
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

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
  console.keyMap = "br-abnt2";

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/4A32A1DB32A1CBEF";
    fsType = "ntfs";
  };

  # 9. System Packages
  environment.systemPackages = with pkgs; [
    heroic
    mangohud
    git
    vim
  ];

  networking.firewall.allowedTCPPorts = [ 22 27036 27037 47984 47989 48010 ];
  networking.firewall.allowedUDPPorts = [ 47998 47999 48000 48002 48010 27031 27036 ];

  system.stateVersion = "25.11";
}
