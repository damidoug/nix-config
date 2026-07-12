{ config, ... }:
{
  home.shellAliases.cd = "z";

  programs = {
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = config.programs.zsh.enable;
      enableFishIntegration = true;
    };

    claude-code.rules.cd = ''
      - `cd` = zoxide (`z`) — smart directory jumping with frecency
      - `z dirname` jumps to most frecent match, `zi` opens interactive picker
    '';
  };
}
