{ pkgs, ... }:

{
  home.packages = with pkgs; [
    distrobox
    podman
  ];

  home.file.".config/distrobox/distrobox.conf".text = ''
    container_manager="podman"
    container_name_default="debian"
    container_image_default="docker.io/library/debian:stable"
  '';
}
