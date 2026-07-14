# llama.cpp benchmarking playbook (pc: Ryzen 9 5950X · RX 580 8 GB · 46 GB RAM)

Goal: measure tokens/sec and *see where a model actually runs* — pure CPU, pure
GPU, or the hybrid (attention on GPU, MoE experts in RAM). Everything here runs
**on the pc** (`ssh pc`). The service is `llama-swap` on `127.0.0.1:11434`.

## The two tools

- **`llama-bench`** — the real benchmark. Reports `pp` (prompt processing) and
  `tg` (token generation) throughput, and sweeps settings for you.
- **`llama-server --metrics`** — already enabled; live tokens/sec at
  `http://127.0.0.1:11434/metrics` while you actually use a model.

Both ship in the same package the service uses. Grab the binaries once:

```fish
# path to the exact llama-cpp-vulkan build this host uses
set llama (nix build --no-link --print-out-paths \
  "/etc/nixos#nixosConfigurations.pc.pkgs.llama-cpp-vulkan")/bin
# GGUFs the service already downloaded live here:
set cache /var/cache/llama-swap
```

(If `llama-bench` isn't in that `bin/`, add `pkgs.llama-cpp-vulkan` to the host's
`environment.systemPackages` temporarily, or run it from a `nix shell`.)

## Watch where the model lives (run in split terminals)

```fish
radeontop            # GPU core % + VRAM used   (or: nvtop)
free -h -s 1         # system RAM in use
```

VRAM climbing = layers on the GPU. RAM climbing instead = weights in DDR4 (CPU).

## The core experiment: CPU vs GPU vs hybrid

Pick one model file, then run the same bench three ways. `-ngl` = number of layers
put on the GPU; `--n-cpu-moe` = number of MoE expert layers *kept on the CPU*.

```fish
set model $cache/(ls $cache | grep -i gpt-oss | grep -i q4 | head -1)

# 1) PURE CPU — nothing on the GPU, all 16 cores
$llama/llama-bench -m $model -ngl 0 -t 16

# 2) MAX GPU — everything that fits in 8 GB VRAM
$llama/llama-bench -m $model -ngl 999

# 3) HYBRID — attention on GPU, experts in RAM (usually the winner on this box)
$llama/llama-bench -m $model -ngl 999 -ncmoe 999
```

Read the **`t/s`** column (generation tokens/sec) in each. On this hardware,
expect the hybrid run to beat both extremes for the MoE models (`gpt-oss`,
`qwen3-coder`) — that's the whole reason for the 5950X + 46 GB pairing.

## Sweep the hybrid split (find where 8 GB VRAM fills)

Push more expert layers onto the GPU until VRAM is full, in one command:

```fish
$llama/llama-bench -m $model -ngl 999 -ncmoe 30,40,50,60 -t 16
```

Lowest `-ncmoe` that doesn't OOM the GPU (watch `radeontop`) is your fastest split.
Bake the winner into `-ncmoe`/`--n-cpu-moe` in `default.nix`.

## Other knobs worth a column

```fish
# Flash attention on/off (Polaris may or may not like it — measure, don't assume)
$llama/llama-bench -m $model -ngl 999 -ncmoe 999 -fa 0,1

# KV-cache quantization: q8_0 halves KV memory (needs -fa 1). More ctx per GB VRAM.
$llama/llama-server -m $model -ngl 999 -fa on -ctk q8_0 -ctv q8_0 -c 32768
```

## Live throughput on the real service

```fish
# ask the running service and read tokens/sec from the metrics endpoint
curl -s http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"main","messages":[{"role":"user","content":"Write a haiku about Nix."}]}' | jq .

curl -s http://127.0.0.1:11434/metrics | grep -E 'tokens_per_second|prompt'
```

Swap `"model":"main"` for `"code"` or `"ocr"` — llama-swap loads that model on
demand (first hit is slow while it loads + downloads on the very first run).

## Turning results into config

The `cmd` strings in `default.nix` are just `llama-server` flags. Once a sweep
tells you the best `-ncmoe`, `-fa`, `-ctk/-ctv`, and `-c` for a model, copy those
numbers into that model's `cmd` and `nixos-rebuild switch`.

## Suggested test matrix (fill in later)

| model | -ngl | -ncmoe | -fa | tg t/s | pp t/s | VRAM | notes |
|-------|------|--------|-----|--------|--------|------|-------|
| main (gpt-oss-20b)   | 0   | –   |   |  |  |  | pure CPU baseline |
| main                 | 999 | 999 |   |  |  |  | hybrid |
| main                 | 999 | 40  |   |  |  |  | more on GPU |
| code (qwen3-coder)   | 999 | 999 |   |  |  |  | hybrid |
| ocr (qwen3-vl-8b)    | 999 | –   |   |  |  |  | dense, should fit VRAM |
