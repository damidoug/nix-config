{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixd
    nixfmt
    nix-prefetch-scripts
    nix-tree
    nixos-anywhere
    nixos-rebuild
    statix
    deadnix
  ];

  programs = {
    zed-editor = {
      extensions = [ "nix" ];
      userSettings = {
        languages.Nix.language_servers = [
          "nixd"
          "!nil"
        ];
        lsp.nixd = {
          binary = {
            path = lib.getExe pkgs.nixd;
            arguments = [ ];
          };
          initialization_options.formatting.command = [
            "${lib.getExe pkgs.nixfmt}"
            "--quiet"
            "--"
          ];
          settings.diagnostic.suppress = [ "sema-extra-with" ];
        };
      };
    };

    helix.languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt;
        }
      ];
      language-server.nixd.config.diagnostic.suppress = [ "sema-extra-with" ];
    };

    claude-code.rules.nix = ''
      - Formatter: nixfmt — run it (or let nixd format-on-save) before considering a `.nix` change done
      - LSP: nixd, not nil — nil is explicitly disabled (`"!nil"`) in Zed, and Helix only has nixd installed
      - Linters: statix (anti-patterns, e.g. unnecessary `with`, `rec`) and deadnix (dead/unused code) — run both over changed files
      - Always use nix flakes — never `nix-env -i`, `nix-channel --add`, or other imperative/channel-based commands
      - Home-manager modules (`programs.*`, `home.*`) configure the user; NixOS/nix-darwin modules configure the system — don't put system-only options in a `homes/` file or vice versa
      - Validate with `nix flake check` before assuming a change is correct; a file that merely parses is not the same as one that evaluates
      - Helix auto-formats nix on save via nixfmt too (moved here from shell/helix, now pinned to the Nix store path instead of relying on PATH)
    '';
  };
}
