{ config, pkgs, ... }:
{
  home.sessionVariables.TERMINAL = "ghostty";

  programs = {
    ghostty = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      enableBashIntegration = true;
      enableZshIntegration = config.programs.zsh.enable;
      enableFishIntegration = config.programs.fish.enable;
      installBatSyntax = config.programs.bat.enable;
    };

    aerospace.settings.mode.main.binding.alt-enter = "exec-and-forget open -a $TERMINAL";

    claude-code.rules.terminal = ''
      - Terminal: ghostty ($TERMINAL = "ghostty")
      - Launch via alt-enter (aerospace keybind)
    '';
  };
}
