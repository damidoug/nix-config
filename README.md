# nix-config

Personal, multi-host Nix flake — NixOS + nix-darwin + home-manager, managed
with [Jujutsu](https://jj-vcs.github.io/jj/) (jj). One typed `host.*` schema
drives every real machine; the same home-manager profile runs on those
machines *and* on standalone (non-NixOS) boxes with no shared code
duplicated between the two.

📖 **[Browse the full site](https://damidoug.github.io/nix-config/)** — a
guided tour of the architecture.

## Hosts

| Host | Platform | Role |
| --- | --- | --- |
| **pc** | NixOS (x86_64) | Daily-driver desktop — GNOME, gaming, and a full self-hosted service stack (Jellyfin, Immich, Vaultwarden, the *arr stack, an AI agent) |
| **pangolin** | NixOS (x86_64, QEMU/VPS) | Internet-facing reverse proxy — [Pangolin](https://github.com/fosrl/pangolin) + Traefik, tunnels every pc service out to a public domain |
| **mac** | nix-darwin (aarch64) | Laptop/workstation — the machine secrets get edited from |

Any Linux box with just Nix + home-manager installed (no NixOS) can also run
this user environment standalone, without becoming a fourth entry in that
table — see [`homes/README.md`](homes/README.md).

## Layout

```
.
├── hosts/     one directory per real machine — { host; module; } per lib/README.md
├── homes/     home-manager profiles, shared by real hosts and standalone machines alike
├── modules/   the shared host.* module tree every host is built from
├── lib/       the builder layer — turns hosts/ and homes/*/machines/ into real flake outputs
├── docs/      this repo's GitHub Pages site
└── secrets.nix, flake.nix
```

| Directory | Covers | Details |
| --- | --- | --- |
| [`modules/`](modules/README.md) | Every `host.*` option and the topic modules that consume it | full module reference, every gotcha hit building it |
| [`lib/`](lib/README.md) | How `hosts/`/`homes/*/machines/` become real flake outputs | the three builders, schema validation, shared nixpkgs config |
| [`homes/`](homes/README.md) | Home-manager profiles — real hosts and standalone machines | the shared baseline, the standalone-machine mechanism |
| [`homes/dami/`](homes/dami/README.md) | One user's full environment | apps/dev/shell breakdown, the philosophy behind the split |

## Quick reference

```sh
# Evaluate everything without building (fast — catches type errors, missing options)
nix flake check

# Deploy a real host (from any machine with SSH access — build happens on the target)
nixos-rebuild switch --flake .#pc       --target-host pc       --build-host pc       --elevate sudo
nixos-rebuild switch --flake .#pangolin --target-host pangolin --build-host pangolin --elevate sudo
darwin-rebuild switch --flake .#mac     # run locally on mac, needs an interactive sudo password

# Activate a standalone machine (Nix + home-manager already installed there)
home-manager switch --flake .#dami@<machine-name>
```

## License

MIT — see [`LICENSE`](LICENSE).
