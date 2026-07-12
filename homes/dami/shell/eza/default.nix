{ config, ... }:
{
  home.shellAliases = {
    ls = "eza";
    ll = "eza -l --git";
    la = "eza -la --git";
    lt = "eza --tree";
  };

  programs = {
    eza = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = config.programs.zsh.enable;
      enableFishIntegration = config.programs.fish.enable;
      git = true;
      icons = "auto";
    };

    claude-code.rules.ls = ''
      - `ls` = eza, `ll` = eza -l --git, `la` = eza -la --git, `lt` = eza --tree
    '';
  };
}
