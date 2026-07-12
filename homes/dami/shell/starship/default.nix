{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs.nerd-fonts; [
    fira-code
    droid-sans-mono
    meslo-lg
  ];

  programs = {
    starship = {
      enable = true;
      # unstable's rust toolchain fails to build starship on aarch64-darwin
      # too — same class of issue as cargo-watch (homes/dami/dev/rust).
      package = pkgs.stable.starship;
      enableBashIntegration = true;
      enableZshIntegration = config.programs.zsh.enable;
      enableFishIntegration = config.programs.fish.enable;
      settings = lib.importTOML ./starship.toml;
    };

    claude-code.rules.starship = ''
      - Shell prompt: starship
      - Config managed declaratively via home-manager (starship.toml)
      - Nerd fonts: FiraCode, DroidSansMono, MesloLG
    '';
  };
}
