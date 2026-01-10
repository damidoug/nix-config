{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "ini"
      "env"
      "toml"
      "sql"
      "make"
      "log"
      "graphql"
      "html"
      "scss"
    ];
    userSettings = {
      telemetry.metrics = false;
      features.copilot = false;
    };
  };

  home.sessionVariables.VISUAL = "zeditor --wait";
}
