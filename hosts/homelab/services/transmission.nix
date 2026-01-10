{
  services.transmission = {
    enable = true;
    group = "media";
    settings.download-dir = "/var/lib/media/downloads";
  };
}
