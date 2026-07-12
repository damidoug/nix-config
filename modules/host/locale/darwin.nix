{ config, lib, ... }:
let
  inherit (lib) filterAttrs;
  inherit (config.host.environment.locale) timeZone language keyboard;
in
{
  config = {
    time.timeZone = timeZone;

    environment.variables = filterAttrs (_: v: v != null) {
      LANG = language.default;
      LC_TIME = language.lcTime;
      LC_MONETARY = language.lcMonetary;
      LC_NUMERIC = language.lcNumeric;
      LC_MEASUREMENT = language.lcMeasurement;
      LC_PAPER = language.lcPaper;
    };

    system.defaults = {
      NSGlobalDomain = {
        AppleFontSmoothing = 1;
        AppleShowAllExtensions = true;
        AppleInterfaceStyle = "Dark";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };

      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleLocale = lib.head (lib.splitString "." language.default);
          AppleLanguages = [ (lib.head (lib.splitString "." language.default)) ];
        };
        "com.apple.HIToolbox" = {
          AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.${lib.strings.toUpper keyboard}";
        };
      };
    };
  };
}
