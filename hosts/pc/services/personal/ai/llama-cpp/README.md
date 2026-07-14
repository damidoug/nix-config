# llama.cpp benchmark results (pc)

`llama-bench` sweep run **2026-07-14** on `pc`, covering pure-CPU vs full-GPU vs
hybrid MoE offload for all three served models. Method and how to re-run: see
[`TESTING.md`](./TESTING.md). Config lives in [`default.nix`](./default.nix).

**Hardware:** Ryzen 9 5950X (16C/32T) · Radeon RX 580 8 GB (RADV Polaris, Vulkan,
`fp16: 0` — no FP16 accel) · 46 GB DDR4.
**Test:** `llama-bench -p 512 -n 128 -t 16`, UD-Q4_K_XL quants. `t/s` is median ± σ.
`pp` = prompt processing (input), `tg` = token generation (output — the number you
feel). `-ncmoe` = `--n-cpu-moe` = MoE expert layers kept on the **CPU** (higher =
more in RAM, lower = more on GPU).

> Caveat: `llama-bench` uses a tiny context, so the KV cache barely uses VRAM here.
> The **production config runs `-c 32768`**, whose KV cache eats VRAM and leaves less
> room for experts — so the best *production* `-ncmoe` is somewhat **higher** than the
> bench-optimal values below. Treat these as the ceiling and the shape of the curve,
> not drop-in production numbers.

## Results

### `main` — gpt-oss-20b (MoE, ~3.6 B active / 21 B, 11.04 GiB)
| config | `-ngl` | `-ncmoe` | pp t/s | **tg t/s** | note |
|---|---|---|---|---|---|
| pure CPU | 0 | – | 182.3 | 9.5 | all 16 cores, GPU idle |
| hybrid (deployed) | 999 | 999 | 196.4 | 16.0 | all experts in RAM, attn on GPU |
| **hybrid + GPU** | 999 | 12 | 238.2 | **25.0** | **fastest** — half the experts on GPU |
| full GPU | 999 | – | 218.0 | 16.9 | 11 GiB > 8 GB VRAM → spills to GTT, slower |

### `code` — Qwen3-Coder-30B-A3B (MoE, ~3.3 B active / 30 B, 16.45 GiB)
| config | `-ngl` | `-ncmoe` | pp t/s | **tg t/s** | note |
|---|---|---|---|---|---|
| pure CPU | 0 | – | 131.4 | 11.0 | |
| hybrid (deployed) | 999 | 999 | 142.8 | 15.7 | all experts in RAM |
| **hybrid + GPU** | 999 | 24 | 94.0 | **20.6** | **fastest tg** (pp drops — GPU busier) |

### `ocr` — Qwen3-VL-8B (dense, 4.79 GiB, fits VRAM)
| config | `-ngl` | pp t/s | **tg t/s** | note |
|---|---|---|---|---|
| pure CPU | 0 | 159.9 | 5.3 | dense = every param every token → CPU hurts |
| **full GPU (deployed)** | 999 | 224.9 | **31.3** | **fastest** — fits entirely in VRAM |

## Takeaways

1. **Hybrid MoE offload wins, and the deployed `-ncmoe 999` is not optimal.** Pushing
   some experts onto the GPU (lower `-ncmoe`) beats keeping them all in RAM:
   - `main`: 16.0 → **25.0** tg/s (**+56 %**)
   - `code`: 15.7 → **20.6** tg/s (**+31 %**)
   This is the single biggest lever. See the caveat above before copying `12`/`24`
   verbatim into the 32 k-context config — the real sweet spot sits a bit higher.

2. **Dense models belong fully on the GPU.** `ocr` at full GPU is **5.9×** its CPU
   speed (31.3 vs 5.3). It fits in 8 GB, so `-ngl 999` with no `-ncmoe` is correct
   (already how it's configured).

3. **Never pure CPU when the GPU can help.** Even for the big MoEs the GPU roughly
   doubles tg (main 9.5 → 25, code 11 → 20.6). The 5950X is strong, but the RX 580
   still earns its keep.

4. **Don't brute-force full-GPU on the big MoE.** `main` at `-ngl 999` (16.9) is
   *slower* than tuned hybrid (25.0): 11 GiB overflows 8 GB VRAM into GTT (system RAM
   over PCIe), which is slower than deliberately keeping experts in RAM. More-on-GPU
   only helps up to where it actually fits.

## Production-context sweep (`-d 32768`) — what's actually deployed

The quick bench above uses a tiny context, so its `-ncmoe` optima are too aggressive.
Re-running at the real 32 k depth (`llama-bench -d 32768`, KV cache fully allocated)
tells a very different — and important — story:

### `main` — gpt-oss-20b @ 32k
| `-ncmoe` | tg t/s | |
|---|---|---|
| 24 (all CPU, ≈ old `999`) | 15.8 | baseline |
| 18 | 18.6 | |
| **16** | **19.8** | **deployed** — +26 %, keeps VRAM headroom |
| 14 | 21.4 | faster but nearer the spill cliff |

### `code` — Qwen3-Coder-30B @ 32k
| `-ncmoe` | tg t/s | |
|---|---|---|
| **48 (all CPU, = `999`)** | **12.5** | **deployed** — fastest |
| 34 | 6.4 | spilled to GTT |
| 30 | 4.1 | worse |
| 28 | 2.9 | worse |

**The lesson:** the optimal split is context-dependent. At 32 k the KV cache claims most
of the 8 GB, so:
- `main` (11 GiB) still has room for ~8 experts on the GPU → `-ncmoe 16` (+26 %).
- `code` (16.45 GiB) has **no** room — moving even a few experts to the GPU overflows
  VRAM into GTT and *halves then quarters* throughput. It must stay all-CPU (`999`).

Had we trusted the small-context bench (which said `code` liked `-ncmoe 24`), we'd have
**wrecked** code's speed (12.5 → ~6). Always tune at the context you actually run.

**Applied to [`default.nix`](./default.nix):** `main` → `--n-cpu-moe 16`, `code` stays
`999`, `ocr` stays full-GPU.
