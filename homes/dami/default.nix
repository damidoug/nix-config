{ ... }:
{
  # base/root module: imports every concern-area (see README.md). Foundational
  # home-manager settings shared by any host's user (home.stateVersion,
  # fonts.fontconfig, xdg.enable, programs.home-manager.enable, programs.man)
  # live in modules/host/home-manager/default.nix instead, not here —
  # anything tool-specific belongs in apps/, dev/, or shell/.
  imports = [
    ./apps
    ./dev
    ./shell
  ];
}
