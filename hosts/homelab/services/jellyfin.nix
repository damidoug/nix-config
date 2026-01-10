{
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  services.nginx.virtualHosts."jellyfin.damidoug.dev" = {
    http2 = true;
    extraConfig = ''
      #Some players don't reopen a socket and playback stops totally instead of resuming after an extended pause
      send_timeout 100m;

      # The default `client_max_body_size` is 1M, this might not be enough for some posters, etc.
      client_max_body_size 20M;

      # Security / XSS Mitigation Headers
      add_header X-Content-Type-Options "nosniff";

      # Permissions policy. May cause issues with some clients
      add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;

      # Content Security Policy
      # See: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
      # Enforces https content and restricts JS/CSS to origin
      # External Javascript (such as cast_sender.js for Chromecast) must be whitelisted.
      add_header Content-Security-Policy "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";

      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Protocol $scheme;
      proxy_set_header X-Forwarded-Host $http_host;

      # Disable buffering when the nginx proxy gets very resource heavy upon streaming
      proxy_buffering off;
    '';
    locations."/" = {
      proxyPass = "http://localhost:8096/";
      proxyWebsockets = true;
    };
  };
}
