{ pkgs, lib, ... }:
{
  # loose CLI utilities that have no home-manager `programs.*` module and no
  # rule of their own — grouped by purpose. Anything with real config lives
  # in its own sibling module instead.
  home.packages =
    with pkgs;
    [
      # network
      curlMinimal
      wget
      rsync

      # media
      ffmpeg

      # data wrangling
      jq
      yq

      # git binary: kept for tool compatibility only (jj is the VCS) — see
      # dev/vcs rule
      gitMinimal
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # clipboard (X11 — Linux only; macOS uses built-in pbcopy/pbpaste)
      xclip

      # hardware inspection (lspci / lsusb — Linux-oriented, PCI/USB bus enumeration)
      pciutils
      usbutils

      # desktop entry management (XDG .desktop files — Linux desktop spec,
      # no equivalent on macOS's .app/Info.plist model)
      desktop-file-utils
    ];
}
