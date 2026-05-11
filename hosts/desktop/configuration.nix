{ config, inputs, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # 1. Boot & Kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "uinput" ]; # Required for Sunshine input emulation
  
  # Force a virtual monitor resolution for headless operation
  # You might need to change HDMI-A-1 to DP-1 or similar depending on your GPU ports
  boot.kernelParams = [ "video=HDMI-A-1:1920x1080@60e" ];

  # 2. Graphics & NVIDIA (Proprietary drivers for NVENC)
  nixpkgs.config.allowUnfree = true;
  
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Older cards can be unstable with this
    open = false; # The "open" kernel module does not support the GTX 1060
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # 3. Sunshine (Streaming Host)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Needed for KMS screen capture
    openFirewall = true; # Opens 47984-48010
  };

  # 4. Networking & VPN
  networking.hostName = "desktop";
  networking.networkmanager.enable = true;
  
  # VPN for remote play
  services.tailscale.enable = true;

  # Enable Avahi for Moonlight discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  # Enable Wake-on-LAN for your specific ethernet interface
  # Find your interface name by running `ip link` (usually enp... or eth...)
  networking.interfaces.enp5s0.wakeOnLan.enable = true; 

  # Standard firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPorts = [
      9
      47998
      47999
      48000
    ]; # Standard port for Wake-on-LAN magic packets
  };

  # 5. Gaming & Optimization
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;

  # Enable Sway (Wayland) for the gaming session
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    extraOptions = [ "--unsupported-gpu" ];
  };

  # 6. User Configuration & Auto-login
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${config.programs.sway.package}/bin/sway --unsupported-gpu";
        user = "kappke";
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd '${config.programs.sway.package}/bin/sway --unsupported-gpu'";
        user = "greeter";
      };
    };
  };

  # Audio for Sunshine
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  programs.zsh.enable = true;
  users.users.kappke = {
    isNormalUser = true;
    description = "Gaming Hub User";
    shell = pkgs.zsh;
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "video" 
      "uinput" # Important for Sunshine to move the mouse/keyboard
      "render"
    ];
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3..." ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "kappke" = import ../../users/kappke.nix;
    };
  };

  # Enable SSH for remote power management
  services.openssh.enable = true;

  # Keyring for password management
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Prevent the system from sleeping/suspending (important for a headless server)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # 7. Localization & Time (Copied from laptop for consistency)
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

  # 8. Storage (Example for your 1TB HDD)
  # Replace UUID with the actual one from `blkid`
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/4A32A1DB32A1CBEF";
    fsType = "ntfs";
  };

  # 9. System Packages
  environment.systemPackages = with pkgs; [
    heroic # For Epic Games and GOG
    lutris # Generic game manager
    mangohud # Performance overlay
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05"; 
}
