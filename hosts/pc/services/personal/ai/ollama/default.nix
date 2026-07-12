{
  pkgs,
  config,
  host,
  ...
}:
let
  ollamaBin = "${config.services.ollama.package}/bin/ollama";

  # Per-model tuning as derived models (see notes/ollama-bench-results/). The
  # stock services.ollama module only exposes ONE global OLLAMA_CONTEXT_LENGTH
  # — a 64k default forced every model to reserve a huge KV cache on the 8 GB
  # card and spill onto the CPU (gemma3:4b dropped from 100% GPU to 55%).
  # Each derived model carries only the context it actually needs.
  derivedModels = {
    # OCR/vision: an image prompt is ~1-2k tokens, never 64k. At 4k ctx gemma3:4b
    # fits entirely in VRAM -> 100% GPU, ~39 tok/s (vs 55% GPU / 32 tok/s at 64k).
    gemma-ocr = ''
      FROM gemma3:4b
      PARAMETER num_ctx 4096
    '';

    # Coding: 24k is plenty for a file + surrounding context and keeps more of the
    # 18 GB MoE on the GPU than 64k did (30% vs 20%). TWO fixes vs the base model:
    #   1. Base qwen3-coder:30b ships a broken template (literally `{{ .Prompt }}`,
    #      no ChatML role markers) so it emits ``` then an immediate stop-token
    #      whenever it would open a reply with a markdown code fence (all HTML/page
    #      requests failed). The ChatML template below restores turn structure.
    #   2. The SYSTEM line tells it to emit raw code, belt-and-suspenders against the
    #      leading-fence trigger. Together: full multi-KB HTML output, verified.
    qwen-code = ''
      FROM qwen3-coder:30b
      TEMPLATE """{{ if .System }}<|im_start|>system
      {{ .System }}<|im_end|>
      {{ end }}{{ if .Prompt }}<|im_start|>user
      {{ .Prompt }}<|im_end|>
      {{ end }}<|im_start|>assistant
      {{ .Response }}<|im_end|>
      """
      PARAMETER num_ctx 24576
      SYSTEM """You are a coding assistant. When asked to write code or produce a file, output the raw code directly. Do NOT wrap your whole response in a single markdown code fence — begin your reply directly with the code itself (for example, start with <!DOCTYPE html> or the first line of the program)."""
    '';

    # hermes-agent's tool schemas + system prompt eat a large fixed prefix and it
    # warns below 64k, so this is the one model that keeps the big context. Inherits
    # the base gpt-oss template (tool handling) — only num_ctx is overridden.
    gpt-oss-agent = ''
      FROM gpt-oss:20b
      PARAMETER num_ctx 65536
    '';
  };

  modelfilesDir = pkgs.linkFarm "ollama-modelfiles" (
    pkgs.lib.mapAttrsToList (name: text: {
      name = "${name}.Modelfile";
      path = pkgs.writeText "${name}.Modelfile" text;
    }) derivedModels
  );
in
{
  services.ollama = {
    enable = true;
    # NOTE: must stay false. syncModels=true runs ollama-model-loader.service, which
    # `ollama rm`s any model not in loadModels — it would delete the derived models
    # below on every activation. The 31-model bench that motivated syncModels is done.
    syncModels = false;
    user = "ollama";
    group = "ollama";
    package = pkgs.ollama-vulkan;
    # Base models pulled from the registry (see 2026-07-05 bench dashboard.html):
    # - gemma3:4b        -> daily OCR/vision (fast + accurate; llama3.2-vision:11b crashed,
    #                       moondream:1.8b was fastest but got object-ID wrong)
    # - gpt-oss:20b      -> daily text-brain + tools (only model, with qwen3.5:9b, that called
    #                       web_search/web_fetch correctly AND declined the no-tool-needed case)
    # - qwen3-coder:30b  -> 48h unattended coding agent (MoE, correct fixes, complete HTML output;
    #                       devstral:24b was equally correct but 5x slower at 2.87 tok/s)
    # Day-to-day you use the derived names (gemma-ocr / qwen-code / gpt-oss-agent), not these.
    loadModels = [
      "gemma3:4b"
      "gpt-oss:20b"
      "qwen3-coder:30b"
    ];
    environmentVariables = {
      # 8GB VRAM can't hold two models loaded simultaneously.
      OLLAMA_MAX_LOADED_MODELS = "1";
      # Polaris (RDNA-less, no FP16 accel) does better without flash attention.
      OLLAMA_FLASH_ATTENTION = "0";
      # Quantized KV cache (q8_0) requires flash_attn, which is off above (segfaults
      # otherwise: "V cache quantization requires flash_attn"), so stay at default f16.
      # Global DEFAULT context for any model called by its base name (e.g. plain
      # `ollama run gpt-oss:20b` for daily chat). Kept modest so daily chat stays
      # mostly on GPU; the models that need more carry their own num_ctx above.
      OLLAMA_CONTEXT_LENGTH = "16384";
    };
  };

  # Create the derived models after the base models are present. Idempotent and cheap
  # (they reuse the base blobs, adding only a template/params layer), so it's safe to
  # re-run on every boot/rebuild — which also re-creates them on a fresh machine.
  systemd.services.ollama-derived-models = {
    description = "Create per-model tuned Ollama variants (context + qwen template fix)";
    after = [ "ollama.service" ];
    requires = [ "ollama.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.services.ollama.user;
      Group = config.services.ollama.group;
      Environment = "OLLAMA_HOST=127.0.0.1:11434";
    };
    script = ''
      # Wait for the ollama server to accept requests.
      until ${ollamaBin} list >/dev/null 2>&1; do sleep 1; done
      ${pkgs.lib.concatStringsSep "\n" (
        pkgs.lib.mapAttrsToList (
          name: _: "${ollamaBin} create ${name} -f ${modelfilesDir}/${name}.Modelfile"
        ) derivedModels
      )}
    '';
  };

  users.users = {
    ${config.services.ollama.user}.extraGroups = [
      "video"
      "render"
    ];

    ${host.environment.user.username}.extraGroups = [
      config.services.ollama.group
    ];
  };
}
