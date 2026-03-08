{ pkgs, inputs, ... }:
{
  # import the home manager module
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.packages = with pkgs; [
    inputs.noctalia-qs.packages.${pkgs.system}.default
  ];

  # configure options
  programs.noctalia-shell = {
    enable = true;
  };
}
