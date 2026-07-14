{
  config,
  lib,
  pkgs,
  host,
  ...
}:
{
  age.secrets.hermes-agent = {
    file = ./secrets.age;
    owner = config.services.hermes-agent.user;
    group = config.services.hermes-agent.group;
  };

  services.hermes-agent = {
    enable = true;
    extraDependencyGroups = [
      "messaging"
      "anthropic"
    ];
    addToSystemPackages = true;
    extraPackages = with pkgs; [
      ripgrep
      ffmpeg
      imagemagick
      pandoc
    ];
    environmentFiles = [ config.age.secrets.hermes-agent.path ];

    settings = {
      timezone = host.environment.locale.timeZone;
      toolsets = [ "all" ];

      # Points at the local llama-swap endpoint (see sibling llama-cpp/default.nix),
      # which serves an OpenAI-compatible /v1 API and hot-swaps the underlying model
      # by name. "main" = gpt-oss-20b — the model that reliably called
      # web_search/web_fetch when needed and declined when not. llama.cpp ignores the
      # api_key value but the OpenAI-compatible client requires a non-empty one.
      model = {
        provider = "auto";
        default = "main";
        base_url = "http://127.0.0.1:11434/v1";
        api_key = "llama";
      };

      terminal.cwd = "/var/lib/hermes/workspace";

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      compression = {
        enabled = true;
        threshold = 0.75;
      };
    };
  };

  # drain_timeout=180s requires TimeoutStopSec >= 210s to avoid mid-drain SIGKILL
  systemd.services.hermes-agent.serviceConfig.TimeoutStopSec = lib.mkForce 210;

  users.users.${host.environment.user.username}.extraGroups = [ config.services.hermes-agent.group ];
}
