{ ... }:
{
  home = {
    shellAliases = {
      vi = "hx";
      vim = "hx";
      nano = "hx";
    };
    sessionVariables.EDITOR = "hx";
  };

  programs = {
    helix = {
      enable = true;
      settings = {
        theme = "autumn_night_transparent";
        editor.cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
      themes.autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };

    claude-code.rules."cli editor" = ''
      - Terminal editor: helix, command `hx` (also aliased as vi/vim/nano)
      - Modal editor: normal/insert/select modes like vim
      - Config managed declaratively via home-manager
      - `$EDITOR` is `hx` — tools that spawn an editor (jj, git, etc.) open helix
      - Per-language LSP/formatter config lives in the matching `dev/<tool>` module, not here
    '';
  };
}
