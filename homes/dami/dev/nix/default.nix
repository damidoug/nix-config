{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixd
    nixfmt
    nixos-rebuild-ng
    nixos-anywhere
  ];

  programs.zed-editor = {
    extensions = [ "nix" ];
    userSettings = {
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp.nixd = {
        initialization_options.formatting.command = [
          "nixfmt"
          "--quiet"
          "--"
        ];
        settings.diagnostic.suppress = [ "sema-extra-with" ];
      };
    };
  };
}
