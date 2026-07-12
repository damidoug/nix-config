{ ... }:
{
  programs = {
    vesktop = {
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

    brave.extensions = [
      "cbghhgpcnddeihccjmnadmkaejncjndb" # vencord web — mirrors the desktop Vencord config above
    ];

    claude-code.rules.vesktop = ''
      - Discord client: vesktop (Vencord-patched Electron client), NOT the official Discord app
      - Vencord plugins enabled: FakeNitro, MessageLogger (ignoreSelf=true) — custom theme via themeLinks (DarkMatter)
      - The "vencord web" Brave extension brings the same Vencord theming to web Discord — installed declaratively, don't suggest installing it manually
    '';
  };
}
