{
  imports = [
    #./adguard.nix
    ./bazarr.nix
    ./beszel.nix
    ./cloudflared.nix
    ./flood.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./nginx.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sonarr.nix
    ./transmission.nix
    ./vaultwarden.nix
  ];

  users.groups.media = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/media 0775 root media -"
    "d /var/lib/media/downloads 0775 root media -"
    "d /var/lib/media/downloads/radarr 0775 root media -"
    "d /var/lib/media/downloads/tv-sonarr 0775 root media -"
    "d /var/lib/media/movies 0775 root media -"
    "d /var/lib/media/tv 0775 root media -"
  ];
}
