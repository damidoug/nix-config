# `homes`

Every home-manager profile in this repo — one directory per user, plus a
shared baseline every profile gets regardless of which machine it runs on.

```
homes/
├── default.nix   recommended baseline, auto-imported for every home
└── dami/         damidoug's full user environment → dami/README.md
    └── machines/   (if present) standalone-machine data files
```

## `default.nix`: the one thing every home has in common

`homes/default.nix` is plain home-manager module syntax — `fonts.fontconfig`,
`xdg.enable`, `programs.man`, `programs.home-manager.enable`, and a correctly
conditional `targets.genericLinux.enable` (only true for a genuinely
standalone, non-NixOS Linux install — see the file itself for how it detects
that). It's auto-imported for **every** home-manager user on **every**
machine, real or standalone — nothing user-specific belongs here. See
`lib/README.md` for exactly where it gets wired in.

## `<user>/`: everything specific to one person

`homes/dami/` is the full per-user environment — GUI apps, dev toolchain,
shell, one directory per concern. See `dami/README.md` for the complete
breakdown and the philosophy behind how it's organized. Adding a second user
means adding a sibling `homes/<user>/` directory with the same shape; nothing
elsewhere in the repo hardcodes "dami" except the actual host files that
declare `environment.user.username`.

## `<user>/machines/`: standalone (non-NixOS/darwin) machines

A machine that isn't one of this repo's real NixOS/darwin hosts — a plain
Ubuntu box with Nix and home-manager installed by hand, for example — is
declared as a small data file here instead of under `hosts/`:
`homes/dami/machines/<machine-name>.nix`. `hosts/` stays reserved for
machines this flake fully owns (boot, disk, services); a standalone machine
gets none of that, just this user's home-manager profile.

```nix
# homes/dami/machines/thinkpad-ubuntu.nix
{
  system = "x86_64-linux";
  # stateVersion, channel, homeDirectory are all optional, sensibly defaulted
}
```

This becomes a `homeConfigurations."dami@thinkpad-ubuntu"` flake output,
activated with `home-manager switch --flake .#dami@thinkpad-ubuntu` once Nix
and home-manager are installed on that machine. Full mechanism, including how
it shares overlays/config with the real hosts, is in `lib/README.md`.
