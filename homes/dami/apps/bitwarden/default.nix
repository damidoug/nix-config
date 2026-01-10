{ pkgs, ... }:
{
  home.packages = [ pkgs.bitwarden-desktop ];

  programs.brave.extensions = [ "nngceckbapebfimnlniiiahkandclblb" ];
}
