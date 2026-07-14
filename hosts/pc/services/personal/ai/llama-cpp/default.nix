{
  lib,
  pkgs,
  host,
  ...
}:
let
  # RX 580 is Polaris (gfx803) — AMD dropped ROCm for it long ago, so Vulkan/RADV
  # is the only GPU path (confirmed: `vulkaninfo` works, `rocminfo` is absent).
  llama = pkgs.llama-cpp-vulkan;
  llamaServer = lib.getExe' llama "llama-server";

  # One OpenAI-compatible endpoint for everything (hermes today, opencode later).
  # Kept on Ollama's old port so nothing downstream has to change.
  port = 11434;

  # Flags shared by every model. ${PORT} is llama-swap's macro — it assigns each
  # model a free port and substitutes it here.
  #   -ngl 999      offload everything that fits to the GPU (per-model tuning below
  #                 decides how much of that the MoE experts claw back to the CPU)
  #   --jinja       use each model's OWN chat template (this natively fixes the
  #                 broken qwen3-coder template the old Ollama config hand-patched)
  #   -t 16         one thread per physical core; leave SMT for the rest of the box
  #   --metrics     expose Prometheus /metrics (live tokens/sec while in use)
  #   --no-webui    it's an API, not a chat page
  #   -fa auto      let llama.cpp decide flash-attn (benchmark knob — see notes)
  common = "--host 127.0.0.1 --port \${PORT} -ngl 999 --jinja -t 16 --metrics --no-webui -fa auto";

  # 8 GB VRAM holds ~one small model. --n-cpu-moe 999 keeps the big MoE *expert*
  # tensors in the 46 GB of DDR4 (the 5950X crunches them) while attention/KV stay
  # on the GPU — the hybrid sweet spot for this "small VRAM, huge CPU/RAM" box.
  # The exact quant tag (:UD-Q4_K_XL) is matched against the GGUF filename; if a
  # first run says "file not found", `-hf <repo>` with no tag lists what's available.
  models = {
    # MAIN — general chat + tools. gpt-oss-20b: MoE, ~3.6B active of 21B, strong
    # tool-calling, and the smallest strong MoE (~12GB MXFP4) so it fits this 8GB-VRAM
    # box better than bigger MoEs. Text-only, which is why `ocr` below is separate.
    # A/B alternative (a touch smarter but ~50% larger, so it fits worse): swap the -hf
    # for `unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q4_K_XL`.
    main = {
      cmd = "${llamaServer} ${common} -hf unsloth/gpt-oss-20b-GGUF:Q4_K_XL -c 32768 --n-cpu-moe 999";
    };

    # CODE — for opencode etc. Qwen3-Coder-30B-A3B: MoE, ~3.3B active of 30B, the
    # strongest local coder in this class. Biggest total weights → leans on RAM most.
    code = {
      cmd = "${llamaServer} ${common} -hf unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_XL -c 32768 --n-cpu-moe 999";
    };

    # OCR / vision — Qwen3-VL-8B. Dense 8B, small enough to sit almost entirely in
    # VRAM (no --n-cpu-moe). `-hf` auto-fetches the paired mmproj vision projector.
    ocr = {
      cmd = "${llamaServer} ${common} -hf unsloth/Qwen3-VL-8B-Instruct-GGUF:Q4_K_XL -c 8192";
    };
  };
in
{
  services.llama-swap = {
    enable = true;
    listenAddress = "127.0.0.1";
    inherit port;
    # Stays CLOSED — access is loopback-only (hermes/opencode on the same host).
    openFirewall = false;
    settings = {
      # Big models take a while to load on first swap; don't health-check them to death.
      healthCheckTimeout = 300;
      # Unload a model after 10 min idle so it hands VRAM + RAM back to the desktop /
      # games (llama-swap otherwise keeps the last model resident forever). The next
      # request just reloads it.
      globalTTL = 600;
      inherit models;
    };
  };

  # Expose the llama-swap web UI (/ui: model playground, live logs, load/unload,
  # token metrics) through Pangolin at llama.<domain>. The service itself stays bound
  # to loopback — newt tunnels in, so the firewall stays closed.
  #
  # auth.sso-enabled is REQUIRED here (not optional like vaultwarden/immich): those
  # apps have their own login page, but llama-swap's UI does not — so Pangolin's SSO
  # is the only thing standing between the internet and a UI that can run inference
  # and load/unload models. Log in with Pangolin credentials to reach it.
  services.newt.blueprint.public-resources.llama-swap = {
    name = "Llama Swap";
    protocol = "http";
    full-domain = "llama.${host.extra.domain}";
    auth.sso-enabled = true;
    targets = [
      {
        hostname = "localhost";
        method = "http";
        inherit port;
        healthcheck = {
          hostname = "localhost";
          inherit port;
          path = "/health";
        };
      }
    ];
  };

  # The module runs llama-swap (and thus the child llama-server processes) under a
  # DynamicUser, so — unlike Ollama's static user — it needs these bolted on:
  #   * video/render groups: access /dev/dri for Vulkan GPU compute
  #   * LLAMA_CACHE on a persistent CacheDirectory: downloaded GGUFs survive restarts
  #     (this is the declarative "model store", replacing Ollama's /var/lib/ollama)
  systemd.services.llama-swap.serviceConfig = {
    SupplementaryGroups = [
      "video"
      "render"
    ];
    CacheDirectory = "llama-swap";
    Environment = [ "LLAMA_CACHE=/var/cache/llama-swap" ];
  };
}
