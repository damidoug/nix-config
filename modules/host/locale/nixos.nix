{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) filterAttrs;
  inherit (config.host.environment.locale) timeZone language keyboard;
in
{
  config = {
    fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;
      fontconfig.enable = true;
    };

    time.timeZone = timeZone;

    i18n = {
      defaultLocale = language.default;
      extraLocaleSettings = filterAttrs (_: v: v != null) {
        LC_TIME = language.lcTime;
        LC_MONETARY = language.lcMonetary;
        LC_NUMERIC = language.lcNumeric;
        LC_MEASUREMENT = language.lcMeasurement;
        LC_PAPER = language.lcPaper;
      };
    };

    console = {
      keyMap = keyboard;
      font = "ter-v16n";
      # console.packages doesn't include terminus_font by default on every
      # host — without it, systemd-vconsole-setup fails to find "ter-v16n"
      # (setfont: ERROR ... Unable to find file).
      packages = [ pkgs.terminus_font ];
    };
  };
}
