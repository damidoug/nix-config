{ pkgs, ... }:
{
  home.shellAliases.cat = "bat --paging=never";

  programs = {
    bat = {
      enable = true;
      extraPackages = [ pkgs.bat-extras.core ];
    };

    # bat's fish integration: batman for man pages, batpipe for less
    fish.interactiveShellInit = ''
      batman --export-env | source
      eval (batpipe)
    '';

    claude-code.rules.cat = ''
      - `cat` = bat (syntax highlighting, no paging)
      - `man` = batman (bat-powered man pages, via MANPAGER)
      - `less` uses batpipe for syntax highlighting automatically
    '';
  };
}
