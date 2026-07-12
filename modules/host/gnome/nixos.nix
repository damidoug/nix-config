{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.host.environment.desktop == "gnome") {
    services = {
      desktopManager.gnome.enable = true;

      displayManager.gdm.enable = true;

      gvfs.enable = true;

      gnome = {
        gnome-keyring.enable = true;
        sushi.enable = true;
        gnome-browser-connector.enable = true;
      };

      tumbler.enable = true;
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    programs = {
      appimage = {
        enable = true;
        binfmt = true;
      };
      dconf = {
        enable = true;
        profiles.gdm.databases = [
          {
            settings = {
              "org/gnome/settings-daemon/plugins/power" = {
                sleep-inactive-ac-type = "nothing";
                sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
                power-button-action = "nothing";
              };
              "org/gnome/desktop/session" = {
                idle-delay = lib.gvariant.mkUint32 0;
              };
            };
          }
        ];
      };
      nautilus-open-any-terminal = {
        enable = true;
        terminal = "ghostty";
      };
      kdeconnect = {
        enable = true;
        package = pkgs.gnomeExtensions.gsconnect;
      };
    };

    environment = {
      systemPackages = with pkgs; [
        ghostty
        gnome-tweaks
        dconf-editor
      ];

      gnome.excludePackages = with pkgs; [
        gnome-tour
        gnome-photos
        gnome-music
        gnome-user-docs
        gnome-maps
        gnome-characters
        gnome-contacts
        gnome-console
        yelp
        epiphany
        geary
        totem
        simple-scan
      ];

      variables = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        SDL_VIDEODRIVER = "wayland,x11";
      };
    };
  };
}
