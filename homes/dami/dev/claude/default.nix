{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    settings.autoUpdates = false;

    plugins = [
      (pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "c4d1925ae9b76a1b641877328209ad25cfeb5ef2";
        hash = "sha256-THnCoQYOe/nKk1mA2+30BwvMrQ6HUPexTOFf9TSJjWg=";
      })
      (pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "d884ae04edebef577e82ff7c4e143debd0bbec99";
        hash = "sha256-kHdQ9e44doBk2yYW88tMSCqVG8ycYcvJSZlrIziXhpA=";
      })
    ];

    rules.environment = ''
      - OS: NixOS (Linux) or macOS via nix-darwin — both built from this one flake, nixpkgs-unstable channel
      - Never edit dotfiles, /etc, or installed apps directly — every persistent change goes through this flake, then a rebuild
      - Apply changes with `darwin-rebuild switch --flake .#mac` (macOS) or `nixos-rebuild switch --flake .#<host>` (NixOS) — never `nix-env -i` or `nix-channel`
      - Before calling a config change done, run `nix flake check` (and ideally `nix build .#<config>.system` / `.#<config>.activationPackage`) to confirm it evaluates and builds
      - Home-manager (user-level) modules live under `homes/<user>/`; system-level modules live under `hosts/<host>/` — check which layer a setting belongs to before adding it
      - `homes/dami/dev/` is organized one directory per tool (see its README) — add new packages/config to the matching tool's module, not to a catch-all file
    '';
  };
}
