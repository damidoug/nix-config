{ pkgs, ... }:
{
  imports = [
    ./gemini
    ./golang
    ./jujutsu
    ./nix
    ./nodejs
    ./podman
    ./python
    ./rust
    ./zed
  ];

  home.packages = with pkgs; [
    gitMinimal
    mitmproxy
    cloudflared
    sqlx-cli
  ];

  home.file."Developer/.keep".text = "";

  programs.brave.extensions = [
    "jlmpjdjjbgclbocgajdjefcidcncaied" # daily.dev
    "gppongmhjkpfnbhagpmjfkannfbllamg" # wappalyzer
  ];
}
