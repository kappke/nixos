{ inputs, pkgs, ... }:
let
  zenPackages = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
  zenBrowserUnwrapped = zenPackages.zen-browser-unwrapped.override (
    pkgs.lib.optionalAttrs (
      pkgs.stdenv.hostPlatform.system == "x86_64-linux"
      && zenPackages.zen-browser-unwrapped.version == "1.23.3b"
    ) {
      # Upstream replaced the 1.23.3b archive after the flake recorded its hash.
      hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
    }
  );
in
{
  home.packages = [
    (zenPackages.default.override { zen-browser-unwrapped = zenBrowserUnwrapped; })
  ];
}
