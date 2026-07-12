{ ... }:
{
  programs = {
    fish = {
      enable = true;
      shellInit = ''
        set -Ux fish_user_paths $HOME/.local/bin /opt/homebrew/bin $fish_user_paths
      '';
    };

    claude-code.rules.shell = ''
      - Shell: fish (NOT bash/zsh)
      - Fish-specific: use `set` not `export`, `function` not `function()`, `and`/`or` not `&&`/`||`
      - Config lives in home-manager, not ~/.config/fish manually
    '';
  };
}
