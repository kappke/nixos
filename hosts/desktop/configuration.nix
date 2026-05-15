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

  # --- Networking ---
  networking.hostName = "gaming-node";
  networking.networkmanager.enable = true;
  networking.interfaces.enp5s0.wakeOnLan.enable = true; 

  # --- NVIDIA Headless Fix ---
  # Without a monitor, the GPU might not initialize a frame buffer.
  # This forces a virtual 1080p display.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  # services.xserver.screenSection = ''
  #   Option "Metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
  #   Option "AllowIndirectGLXProtocol" "off"
  #   Option "TripleBuffer" "on"
  # '';
  #
  # services.xserver.config = ''
  #   Section "Device"
  #       Identifier     "Device0"
  #       Driver         "nvidia"
  #       VendorName     "NVIDIA Corporation"
  #       # This allows the driver to work without a physical monitor
  #       Option         "AllowEmptyInitialConfiguration" "true"
  #       Option         "ConnectedMonitor" "DFP"
  #       Option         "CustomEDID" "DFP:/etc/X11/edid.bin"
  #   EndSection
  # '';

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; 
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  swapDevices = [ { device = "/var/lib/swapfile"; size = 8192; } ];
  
  hardware.graphics = {
    enable = true;
    # driSupport32Bit = true;
    enable32Bit = true; # Required for Steam
  };

  # --- Gaming Stack ---
  programs.steam.enable = true;
  # services.sunshine = {
  #   enable = true;
  #   autoStart = true;
  #   capSysAdmin = true;
  #   openFirewall = true;
  #   settings = {
  #     video_encoder = "nvenc";
  #   };
  # };

  # --- User Configuration ---
  users.users.kappke = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "render" ];
    # Add your laptop's public key here to allow remote 'nixos-rebuild'
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..." 
    # ];
  };

  # Automatic login is required for Sunshine to capture the desktop
  services.displayManager.autoLogin = {
    enable = true;
    user = "kappke";
  };
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.windowManager.openbox.enable = true;
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.desktopManager.gnome.enable = true;

  # services.udev.extraRules = ''
  #   KERNEL=="uinput", GROUP="video", MODE="0660", OPTIONS+="static_node=uinput"
  # '';

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
