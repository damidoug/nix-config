{
  programs.vesktop = {
    enable = true;
    settings = {
      discordBranch = "stable";
      hardwareAcceleration = true;
      hardwareVideoAcceleration = true;
    };
    vencord.settings = {
      autoUpdate = true;
      autoUpdateNotification = true;
      useQuickCss = true;
      disableMinSize = true;
      plugins = {
        FakeNitro.enabled = true;
        MessageLogger = {
          enabled = true;
          ignoreSelf = true;
        };
      };
      themeLinks = [ "https://discordstyles.github.io/DarkMatter/DarkMatter.theme.css" ];
    };
  };

  programs.aerospace.settings.mode.main.binding.alt-d = "exec-and-forget open -a Vesktop";

  programs.brave.extensions = [ "cbghhgpcnddeihccjmnadmkaejncjndb" ];
}
