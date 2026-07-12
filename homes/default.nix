# Recommended baseline home-manager config, auto-imported for every home
# (see modules/host/home-manager/default.nix) — anything tool-specific
# belongs in a homes/<user>/{apps,dev,shell} module instead.
{
  pkgs,
  osConfig ? null,
  ...
}:
{
  programs.home-manager.enable = true;

  fonts.fontconfig = {
    enable = true;
    hinting = "slight";
    antialiasing = true;
    subpixelRendering = "rgb";
  };

  xdg.enable = true;

  # home-manager defaults programs.man.package to null on darwin once
  # home.stateVersion >= "26.05" (defers to macOS's own man), which makes
  # generateCaches a no-op — set an explicit package so mandb actually
  # builds the apropos/whatis cache, same as it already does on nixos.
  programs.man = {
    generateCaches = true;
    package = pkgs.man;
  };

  # targets.genericLinux is for a standalone (non-NixOS) Linux install.
  # `osConfig` is only ever set when home-manager runs integrated as a
  # NixOS/darwin module (home-manager's own nixosModules/darwinModules
  # inject it as the parent system's config) — null means standalone. Every
  # Linux host in this repo today runs home-manager as a NixOS module, so
  # this evaluates false here, but the condition is real rather than
  # hardcoded off, for whenever that's no longer true.
  targets.genericLinux.enable = pkgs.stdenv.isLinux && osConfig == null;
}
