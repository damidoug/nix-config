{ config, ... }:
{
  programs = {
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = config.programs.zsh.enable;
      enableFishIntegration = config.programs.fish.enable;
    };

    claude-code.rules.fzf = ''
      - Fuzzy finder: fzf — Ctrl+R (history search), Ctrl+T (file picker), Alt+C (cd into dir)
    '';
  };
}
