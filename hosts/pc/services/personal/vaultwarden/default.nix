{
  config,
  host,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  age.secrets.vaultwarden = {
    file = ./secrets.age;
    owner = "vaultwarden";
    group = "vaultwarden";
  };

  services = {
    vaultwarden = {
      enable = true;
      environmentFile = config.age.secrets.vaultwarden.path;
      config = {
        # --- Network ------------------------------------------------------------
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;

        # --- Identity -----------------------------------------------------------
        DOMAIN = "https://vault.${host.extra.domain}";
        HELO_NAME = "vault.${host.extra.domain}"; # SMTP HELO — must match domain for deliverability

        # --- Access control -----------------------------------------------------
        # Personal instance — nobody can self-register; admin must invite.
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = true;

        # No organisations on a personal instance.
        ORG_CREATION_ALLOWED = false;

        # Allow Bitwarden Send (encrypted text/file sharing) and email changes.
        SENDS_ALLOWED = true;
        EMAIL_CHANGE_ALLOWED = true;

        # --- Security -----------------------------------------------------------
        # Require email verification on every new device login — catches stolen
        # passwords before the attacker can do anything with them.
        REQUIRE_DEVICE_EMAIL = true;

        # Force 2FA on every login — do not let devices skip it for 30 days.
        DISABLE_2FA_REMEMBER = true;

        # Login rate limiting — matches Vaultwarden defaults; explicit so intent
        # is clear and changes are reviewed rather than silently inherited.
        LOGIN_RATELIMIT_MAX_BURST = 10; # allow short bursts (autofill retries)
        LOGIN_RATELIMIT_SECONDS = 60; # per-minute window

        # Admin panel — stricter than login: 3 attempts then 5 min lockout.
        ADMIN_RATELIMIT_MAX_BURST = 3;
        ADMIN_RATELIMIT_SECONDS = 300;

        # Keep the admin panel token-protected (never disable it).
        DISABLE_ADMIN_TOKEN = false;

        # Real client IP forwarded by Pangolin for rate limiting.
        IP_HEADER = "X-Real-IP";

        # WebSocket notifications — served on the main Rocket port since v1.29.
        WEBSOCKET_ENABLED = true;

        # --- Push notifications (EU servers) ------------------------------------
        # Enables mobile push for the Bitwarden app (vault sync, 2FA).
        # PUSH_INSTALLATION_ID and PUSH_INSTALLATION_KEY are in the secret file.
        PUSH_ENABLED = true;
        PUSH_RELAY_URI = "https://api.bitwarden.eu";
        PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";

        # --- SMTP (non-secret) --------------------------------------------------
        # Credentials (host, port, security, username, password) are in the secret file.
        SMTP_FROM = "vault@${host.extra.domain}";
        SMTP_FROM_NAME = "Vaultwarden";
        SMTP_EMBED_IMAGES = true;

        # Never accept invalid TLS certs or hostnames from the SMTP relay.
        SMTP_ACCEPT_INVALID_CERTS = false;
        SMTP_ACCEPT_INVALID_HOSTNAMES = false;

        # --- Logging ------------------------------------------------------------
        # "warn" catches auth failures and suspicious events without being noisy.
        # "critical" would silence too much on a security-sensitive service.
        ROCKET_LOG = "warn";
      };
    };

    newt.blueprint.public-resources.vaultwarden = {
      name = "Vaultwarden";
      protocol = "http";
      full-domain = "vault.${host.extra.domain}";
      targets = [
        {
          hostname = "localhost";
          method = "http";
          port = config.services.vaultwarden.config.ROCKET_PORT;
          healthcheck = {
            hostname = "localhost";
            port = config.services.vaultwarden.config.ROCKET_PORT;
            path = "/alive";
          };
        }
      ];
    };
  };

  systemd.services.vaultwarden = {
    serviceConfig = {
      Restart = mkForce "always";
      RestartSec = mkForce "5s";
      StateDirectoryMode = mkForce "0700";
    };
    unitConfig.StartLimitIntervalSec = mkForce 0;
  };
}
