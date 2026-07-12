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

      # Repointed at the local Ollama instance (see sibling ollama/default.nix) —
      # gpt-oss:20b was the only local model tested that reliably called
      # web_search/web_fetch when needed and correctly declined when not
      # (see notes/ollama-bench-results/dashboard.html). Ollama ignores the
      # api_key value but the OpenAI-compatible client requires a non-empty one.
      #
      # Uses the gpt-oss-agent variant (gpt-oss:20b baked at num_ctx 64k) rather
      # than the base model: hermes' tool schemas + system prompt need the large
      # context, and the OpenAI /v1 endpoint can't pass num_ctx per request, so the
      # context has to live in the model itself. Daily chat still uses plain
      # gpt-oss:20b at the smaller global default for speed.
      model = {
        provider = "auto";
        default = "gpt-oss-agent";
        base_url = "http://127.0.0.1:11434/v1";
        api_key = "ollama";
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
