{
  programs = {
    fastfetch.enable = true;

    claude-code.rules.fastfetch = ''
      - System info display: `fastfetch`
      - Config managed declaratively via home-manager
    '';
  };
}
