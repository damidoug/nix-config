# See hosts/pc/default.nix for the shape/rationale of the { host; module; } split.
{
  host = {
    name = "mac";
    system = "aarch64-darwin";
    channel = "unstable";
    type = [
      "workstation"
      "laptop"
    ];

    environment = {
      user = {
        username = "dami";
        fullName = "Douglas Damiano";
      };

      locale = {
        timeZone = "Europe/Malta";
        keyboard = "us";
        language = {
          default = "en_US.UTF-8";
          lcTime = "en_IE.UTF-8";
          lcMonetary = "en_IE.UTF-8";
          lcNumeric = "en_IE.UTF-8";
          lcMeasurement = "en_IE.UTF-8";
          lcPaper = "en_IE.UTF-8";
        };
      };
    };

    hardware.display = true; # external monitors via MonitorControl

    tools = {
      # dami@macbook-air's own personal key (secrets.nix's editorKeys) is the
      # one used to run `agenix -e`/`-d`/`--rekey` — this is the machine that
      # actually needs the CLI installed (see lib/hostSchema.nix's
      # `tools.agenix.enable` comment). mac owns no hosts/mac/** secrets
      # today, but enable=true now also injects the `age.secrets` module, so
      # a publicKey is required regardless — this machine's own SSH host key.
      agenix = {
        enable = true;
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBe2GZBPgB1efmHJLaQhm/PR/yHla5GNAmIn6Lz5CvJk";
      };
      homeManager.enable = true;
    };

    darwinStateVersion = 6;
  };

  module = { };
}
