{
  pkgs,
  lib,
  osConfig ? { },
  ...
}:
{

  programs.brave = {
    enable = true;
    dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
    nativeMessagingHosts = with pkgs; [
      # Plasma 6 (New Standard)
      (lib.mkIf (osConfig.services.desktopManager.plasma6.enable or false
      ) kdePackages.plasma-browser-integration)

      # Plasma 5 (Legacy Standard)
      (lib.mkIf (osConfig.services.xserver.desktopManager.plasma5.enable or false
      ) libsForQt5.plasma-browser-integration)

      # Gnome
      (lib.mkIf (osConfig.services.desktopManager.gnome.enable or false) gnome-browser-connector)
    ];
  };

  programs.aerospace.settings.mode.main.binding.alt-b = "exec-and-forget open -a 'Brave Browser'";
}
