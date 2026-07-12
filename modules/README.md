# `modules`

Shared NixOS/nix-darwin config, factored out of `hosts/{pc,pangolin,mac}/base/`.
Every real per-host setting lives under one `host.*` NixOS/darwin option
namespace, declared once in `lib/hostSchema.nix` and consumed by topic
modules under `modules/host/<topic>/{nixos,darwin}.nix`. `lib/mkConfigurations.nix`
injects the *whole* `modules/host` tree unconditionally for every host — no
host hand-curates an `imports` list for any of this. Same one-dir-per-concern
convention as `homes/dami/` — see its top-level README for the shared
philosophy.

`host.*` is organized into three themed sub-groups plus a small set of flat
machine-identity fields — see "`host.hardware`/`host.environment`/`host.tools`"
below for the full grouping rationale. Topic modules below are annotated with
their real path (`host.hardware.X`, `host.environment.X`, etc), not the bare
field name.

This file covers the module tree itself. For how `hosts/<name>/default.nix`
gets turned into a real `nixosConfigurations`/`darwinConfigurations` entry
(or how a standalone home-manager machine becomes a `homeConfigurations`
entry), see `lib/README.md`.

```
modules/
├── host/
│   ├── default.nix          options.host (reuses lib/hostSchema.nix as its
│   │                        submodule type) + the host→config.host bridge +
│   │                        platform-gated imports + system.stateVersion
│   ├── home-manager/         only imported when host.tools.homeManager.enable
│   │                         — useUserPackages/useGlobalPkgs/extraSpecialArgs
│   │                         and per-user home.stateVersion, then imports
│   │                         homes/default.nix (the recommended baseline,
│   │                         shared with standalone machines — see
│   │                         lib/README.md) plus homes/<username>/ if it
│   │                         exists. Which home-manager *release* gets
│   │                         injected follows host.tools.homeManager.channel
│   │                         (see "channel-paired inputs" section below)
│   ├── nix/                 cross-platform — nix.conf, gc, allowUnfree,
│   │                        permittedInsecurePackages, mylib overlay, aliases;
│   │                        branches on the `host` specialArg's isLinux/isDarwin
│   ├── openssh/{nixos,darwin}.nix   both enabled whenever
│   │                                host.environment.user.sshKeys != [];
│   │                                nixos gets .settings + openFirewall + fail2ban,
│   │                                darwin gets only enable + raw extraConfig text
│   │                                (toggles Apple's Remote Login, no fail2ban at all)
│   ├── audio/nixos.nix        host.hardware.audio (bool) — pipewire + rtkit
│   ├── bluetooth/nixos.nix    host.hardware.bluetooth (bool) —
│   │                          hardware.bluetooth + a native mpris-proxy
│   │                          systemd.user unit
│   ├── boot/nixos.nix         host.hardware.boot.{efiSupport,efiMountPoint} —
│   │                          grub, standardized across hosts, recommended
│   │                          defaults
│   ├── cpu/nixos.nix          host.hardware.cpu = "intel" | "amd" | null
│   │                          (asserted non-null)
│   ├── gpu/nixos.nix          host.hardware.gpu.{amd,intel,nvidia} — one
│   │                          nullable submodule per vendor (asserted:
│   │                          exactly one non-null); intel always gets
│   │                          `i915.enable_guc=3`, gpu.intel.probe (nullOr
│   │                          str) adds `i915.force_probe=<id>` on top;
│   │                          gpu.amd.legacy/gpu.nvidia.legacy pick the
│   │                          legacy si/cik kernel params or closed nvidia
│   │                          driver respectively
│   ├── gnome/nixos.nix        gated on host.environment.desktop == "gnome"
│   ├── disk/nixos.nix         host.hardware.disk.{type,fileSystem,disko,folders} —
│   │                          asserts type/fileSystem/disko.devices.disk are
│   │                          all set; autoScrub/fstrim inferred from
│   │                          type/fileSystem, but as `mkDefault` (see disk/
│   │                          section below); `folders` (listOf {path,mode,
│   │                          user,group}) becomes systemd.tmpfiles.rules —
│   │                          populated by service modules anywhere in the
│   │                          tree, not just the host's own file, since
│   │                          list-typed options merge across modules
│   ├── locale/{nixos,darwin}.nix    host.environment.locale.{timeZone,keyboard,language.*}
│   ├── networking/{nixos,darwin}.nix   host.environment.networking.{interface,
│   │                                   dns,networkd.*} — asserts interface
│   │                                   and static.addresses are set when
│   │                                   networkd.enable is true
│   ├── power/{nixos,darwin}.nix   host.isServer/isLaptop-driven logind/tlp
│   │                              (nixos), or Battery Toolkit + pmset +
│   │                              MonitorControl (darwin, the latter gated
│   │                              on host.hardware.display) —
│   │                              unconditional except the MonitorControl half
│   └── user/{nixos,darwin}.nix    host.environment.user.{username,fullName,sshKeys,...}
```

There is no darwin-only module tree anymore (`modules/darwin` — it only ever
held `display`, which moved into `power/darwin.nix` above). Homebrew
(nix-darwin's declarative cask management) was tried and removed — GUI apps
that fail to build from source on darwin (see `bitwarden` below) are just not
installed there for now rather than routed through a second package manager.

**Nothing above is hand-imported by a host.** `lib/mkConfigurations.nix`
unconditionally injects `modules/host` into every host's `modules` list. A
host's own file only ever lists genuinely host-unique things (`./base`, pc's
`./gaming`/`./services`) — it structurally *cannot* forget to wire in an
essential module tree, because it no longer wires one in at all.

Each host's own top-level `hosts/<name>/default.nix` returns
`{ host; module; }` (see the `host` section below for why) and looks like:

```nix
{
  host = {
    name = "pc";
    system = "x86_64-linux";
    channel = "unstable";
    type = [ "desktop" "workstation" "server" ];
    extra.domain = "damidoug.dev"; # escape hatch, see "extra" section below

    hardware = {
      audio = true;
      bluetooth = true;
      boot.efiSupport = true;
      cpu = "amd";
      gpu.amd.legacy = true; # only amd is non-null -> single-vendor assertion passes
      disk = { type = "nvme"; fileSystem = "btrfs"; disko.devices.disk = { ... }; };
    };

    environment = {
      desktop = "gnome";
      locale = { timeZone = "Europe/Malta"; keyboard = "us"; language.default = "en_US.UTF-8"; };
      user = { username = "dami"; sshKeys = [ ... ]; };
      networking.interface = "eno1";
    };

    tools = {
      # enable defaults false — only set where the CLI is actually needed
      # locally (see "host.tools.agenix" section below)
      agenix.publicKey = "ssh-ed25519 ...";
      homeManager.enable = true; # channel = null -> follows `channel` above
    };
  };

  module = { config, inputs, ... }: {
    imports = [ inputs.hermes-agent.nixosModules.default ./gaming ./services ];
    systemd.tmpfiles.rules = [ "d /games 0755 ${config.host.environment.user.username} ... - -" ];
  };
}
```

No host sets `system.stateVersion` in its own `module` block — `modules/host/default.nix`
sets it automatically from `host.isLinux`/`isDarwin`: NixOS gets
`host.stateVersion` (the "26.05"-style string) directly; darwin gets
`host.darwinStateVersion` (a small separate integer — nix-darwin tracks its
own module-compat version independently of the nixpkgs release string, not
derivable from it, so it's its own field, e.g. `darwinStateVersion = 6;` on
mac). darwin's `system.nixpkgsRelease` is *not* set anywhere — it's
`readOnly` there, auto-derived by nix-darwin from the nixpkgs flake input
itself (initially assumed it needed setting from `host.stateVersion` too;
turned out to already be handled).

`host` fields with no meaningful "off" state for a given host (a server has no
`desktop`, mac has no `cpu`/`gpu`) simply stay unset — their defaults (`null`
for enums, `false` for bools, `[]`/`{}` for lists/attrs) make the
corresponding topic module inert rather than needing a `.enable` per field.

## `host` — one file per host, typed and validated before the module fixpoint, then mirrored into a real option

`hosts/<name>/default.nix` returns `{ host; module; }`, not a bare module
function and not a separate `meta.nix` — `host` is plain data, `module` is
the actual NixOS/darwin module. `lib/mkConfigurations.nix` imports the file
and reads `.host` directly, outside the module fixpoint — this is what lets
it decide `nixosSystem` vs `darwinSystem` and the nixpkgs channel *before*
any module evaluation starts, something no option inside `module` could ever
answer. `.module` only ever gets passed into `nixosSystem`/`darwinSystem`'s
`modules` list, never read directly.

`host` is validated and enriched by `lib/hostSchema.nix` via
`lib.evalModules`, using the flake's own top-level `lib` (never the per-host
`channel`, since this runs before that choice is even resolved). The
validated result becomes the `host` specialArg passed to every injected
module — but it is *also* mirrored into a real NixOS option, `config.host`,
by `modules/host/default.nix`:

```nix
options.host = lib.mkOption {
  type = lib.types.submodule (import ../../lib/hostSchema.nix);
};
config.host = builtins.removeAttrs host [ "arch" "os" "isLinux" "isDarwin" "isDesktop" "isLaptop" "isServer" "isWorkstation" "isQemu" ];
```

This reuses `lib/hostSchema.nix` itself as the submodule type, so the
pre-fixpoint schema and the real option never drift out of sync — one
declaration, two evaluations (one via `lib.evalModules` for the early
builder-selection pass, one as a genuine submodule inside the real
NixOS/darwin fixpoint). Every topic module reads `config.host.*`; the `host`
specialArg still exists too, for leaf configs (`hosts/pc/gaming`,
`hosts/pc/services`) that just want plain data without going through the
module system.

**Why the derived fields get stripped before the bridge**: `host` (the
specialArg) already carries `arch`/`os`/`isLinux`/`isDarwin`/`isDesktop`/
`isLaptop`/`isServer`/`isWorkstation`, computed once by `lib/hostSchema.nix`'s
own `config` block during the pre-fixpoint pass. Since `config.host` reuses
that same schema as its type, it *independently re-derives* those same
`readOnly` fields from `system`/`type` a second time. Passing the
already-computed values back in as part of `config.host = host;` creates a
second *definition* of a field NixOS considers `readOnly` — even though both
definitions agree numerically, NixOS refuses (`is read-only, but it's set
multiple times`). Stripping them lets the submodule derive them itself; same
pure computation, same result, no double-definition.

## `host.hardware`/`host.environment`/`host.tools` — three themed groups, only machine-identity fields stay flat

`host.*` grew to ~15 flat top-level fields as capabilities accumulated
session over session; it's now organized into three sub-groups, each
documented at the point it's declared in `lib/hostSchema.nix`:

- **`host.hardware`** — `cpu`, `gpu` (one nullable submodule per vendor, see
  its own section below), `audio`, `bluetooth`, `display`, `boot`, `disk`.
  Properties of the physical (or virtual, for `display`'s darwin case)
  machine.
- **`host.environment`** — `desktop`, `locale`, `networking`, `user`. How the
  OS is configured for a human to use it — distinct from raw hardware and
  from tooling. (Named `environment`, not `system` — that name was already
  taken by the flat `host.system` field, e.g. `"x86_64-linux"`.)
- **`host.tools`** — `agenix`, `homeManager`. Software infrastructure a host
  opts into, each with its own `enable` + settings.

Only genuine machine-identity fields stay flat on `host.*` directly: `name`,
`system`, `channel`, `type`, `stateVersion`, `darwinStateVersion`, `extra`,
plus the 9 derived readOnly fields (`arch`/`os`/`isLinux`/etc). `extra`
itself stays flat too — it's a foundational escape hatch (see its own
section below), not itself a themed group.

This is a pure reorganization, not a behavior change — every topic module's
*consumption* of a value moved with it (e.g. `config.host.audio` →
`config.host.hardware.audio`), but no value's meaning changed. Verified
concretely: forced `system.build.toplevel.drvPath` for all three hosts
before/after — pangolin came back **byte-identical**; pc and mac shifted
(pc because `hermesAgent` moved from a `capabilities`-gated central
injection to a direct import in its own `module` block — a real
list-construction-order change, not just a rename; mac from schema
declaration reordering rippling into the derivation despite no resolved
value changing) — confirmed via targeted resolved-value spot-checks instead
(`host.hardware.cpu`, `host.environment.user.username`,
`host.tools.agenix.publicKey`, `services.hermes-agent.enable`, mac's
`environment.variables.LC_TIME`, etc — see git-free history / this session's
own verification notes for the full list), not just the drvPath diff.

## `capabilities` removed entirely — `hermesAgent` was its last field, now a direct import

`host.capabilities` used to hold `agenix`/`disko`/`homeManager`/`hermesAgent`;
each left one at a time as it either became unconditional (`agenix`/`disko`
— every host gets agenix, every Linux host gets disko, so
`lib/mkConfigurations.nix`'s `extraModules` injects both directly, no flag
to read) or outgrew a bare bool (`homeManager` needed a `channel` alongside
`enable`, so it became its own `host.tools.homeManager` group). `hermesAgent`
was the last field left, and it has exactly one consumer — pc — with no
shared mechanism ever needed for it, the same reasoning already applied to
*not* build a multi-host-secret escape hatch in `secrets.nix` until there's
a second user (see that file's own header comment). Rather than keep a
one-field `capabilities` submodule alive for a single host's single flag,
`capabilities` was deleted outright: `hosts/pc/default.nix`'s own `module`
function now takes `inputs` as an argument and lists
`inputs.hermes-agent.nixosModules.default` directly in its `imports`,
alongside its existing `./gaming`/`./services` — exactly the pattern pc
already used for its own host-unique subdirectories, just with a third,
flake-input-sourced entry. mac and pangolin need no change (neither ever set
`hermesAgent = true`).

## `host.tools.agenix`: schema-only, no topic module — gates the module + CLI package, scopes `secrets.nix`

`host.tools.agenix = { enable; publicKey; }` has no `modules/host/agenix/`
directory — its only consumers are `lib/mkConfigurations.nix` (gates both
`inputs.agenix.{nixosModules,darwinModules}.default` — the real `age.secrets`
module — and the CLI package via `environment.systemPackages` on the single
`enable` flag) and the repo-root `secrets.nix` (scopes which `.age` files
each host's own key can decrypt), same "schema-only" shape `host.capabilities`
used to have. Lives under `host.tools`, not `host.extra` — agenix is
core infrastructure a host explicitly opts into, not a one-off value like
`host.extra.domain`. Any host with `enable = true` is asserted
(`lib/mkConfigurations.nix`'s `assertHost`) to also set `publicKey`, since a
host with the module but no key could never be scoped as a decrypt recipient
by `secrets.nix` anyway. Today all three hosts set `enable = true`: pc and
pangolin because they own real secrets, mac because it's the machine used to
edit secrets interactively (`agenix -e`) even though it owns none itself.

`publicKey` is a single `nullOr str`, not a list — an earlier iteration made
it a list (`sshKeys`) for hypothetical key-rotation flexibility, but the
only key ever actually needed is the host's own root SSH host key
(`/etc/ssh/ssh_host_ed25519_key.pub`, matching `age.identityPaths`' default
identity), so it was simplified back down. `secrets.nix` scopes every
`hosts/<name>/**` `.age` file to `editorKeys ++ [ host.tools.agenix.publicKey ]`
for its owning host `<name>` (inferred purely from path — a file under
`hosts/<name>/**` is owned by `<name>`, no per-secret config needed; see
`secrets.nix`'s own header comment for the full mechanism) — never to every
host in the repo, fixing a real blast-radius problem where any host could
previously decrypt any other host's secrets (pangolin, internet-facing,
could decrypt pc's vaultwarden/qbittorrent-VPN/hermes secrets and vice
versa). `enable` defaults `false` — a host that neither owns secrets nor
edits them locally needs neither the module nor the CLI. A host left at the
default with no `publicKey` set makes `secrets.nix` throw a clear error
naming the host if it turns out to own a secret anyway, rather than silently
mis-scoping it — same for a `.age` file that doesn't match any host
directory at all. Both throws were deliberately triggered against the real
repo (in scratch files, never touching real ciphertext) before trusting
them, same discipline as every other assertion in this doc.

**`secrets.nix` deliberately never reads `tools.agenix.enable` at all** —
it only reads `publicKey`. Earlier, `enable` gated only the CLI package
while the `age.secrets` module was injected unconditionally for every host;
`enable` was later extended to also gate the module itself (a host that
enables agenix at all gets both), but `secrets.nix`'s own logic didn't need
to change — it was always really asking "does this host have a key to
scope this secret to," which `publicKey == null` answers directly regardless
of what `enable` happens to control on the module-injection side.

Cutting over requires an `agenix --rekey` (re-encrypts every `.age` file's
*ciphertext* under its new, narrower recipient set — `secrets.nix` alone
only changes the *target*, not what's already on disk) — this is a manual,
human-run step: it needs a real identity able to decrypt the *current*
ciphertext interactively (passphrase-protected), which cannot be scripted or
piped by an agent.

## nix-darwin and home-manager have channel-paired stable variants — `host.channel` picks them automatically

`nixpkgs-stable` is pinned to `nixos-26.05` (`flake.nix`). nix-darwin and
home-manager both publish a matching stable branch — nix-darwin-26.05,
home-manager's release-26.05 — alongside their default `master` branch (the
one that pairs with nixpkgs unstable/master). Four flake inputs now exist:
`nix-darwin`/`nix-darwin-stable` and `home-manager`/`home-manager-stable`,
each `-stable` variant with `inputs.nixpkgs.follows = "nixpkgs-stable"` (the
non-stable ones follow plain `nixpkgs`, i.e. unstable).

`lib/mkConfigurations.nix` picks between them with two small lookup tables,
`darwinInputs`/`homeManagerInputs = { unstable = ...; stable = ...-stable;
master = ...; }` (`unstable` and `master` both map to the same default/master
branch — there's no separate "master" branch of nix-darwin or home-manager
distinct from their default branch, unlike nixpkgs which has three real
branches). `mkDarwin` indexes `darwinInputs.${host.channel}` directly — no
override, because pairing nix-darwin's rolling branch against
`nixpkgs-stable` isn't just discouraged, it isn't guaranteed to evaluate at
all. `extraModules`' home-manager injection instead resolves through
`homeManagerChannel host` (`host.tools.homeManager.channel`, falling back to
`host.channel` when `null` — "automatic"), since home-manager-stable is only
*recommended* for a stable host, not required — a host can set
`tools.homeManager.channel` explicitly to get either variant independent of
its own `channel`.

Verified both paths for real, not just that they evaluate: forced a
throwaway mac copy to `channel = "stable"` and confirmed
`system.build.toplevel.drvPath`'s store-path suffix names the actual
nix-darwin-26.05 commit and `system.nixpkgsRelease == "26.05"`; separately
set `homeManager.channel = "stable"` on pc (which stays on `channel =
"unstable"` otherwise) and confirmed home-manager's own internal
release-mismatch warning (`home.enableNixpkgsReleaseCheck`) fired — direct
evidence home-manager-stable (release 26.05) was genuinely injected against
an unstable host, not just that the option accepted the value. All three real
hosts came back with byte-identical `drvPath`s before/after this change, since
none of them actually exercise the new stable-darwin or channel-override
paths today (pc/mac stay unstable, pangolin has no home-manager at all).

## `host.extra` — an escape hatch for values that don't warrant their own schema field

Not every per-host value needs a dedicated `lib/hostSchema.nix` option.
`domain` was the first and so far only example — used by a handful of
`hosts/pc/services/*` modules and pangolin's own module for building
subdomains (`photos.${host.extra.domain}` etc.) — genuinely host-specific
data, but not a concern any topic module under `modules/host/` needs to know
about the way `cpu`/`gpu`/`disk` are. `host.extra` is `attrsOf anything`
with no fixed field list (deliberately the *only* freeform option in the
schema — everything else stays strict specifically so typos are caught, per
the header comment in `lib/hostSchema.nix`), read as `host.extra.domain` or
`config.host.extra.domain` same as any other field. Add new keys here first;
only promote one to a real `mkOption` if it grows enough validation/reuse to
be worth it (a second consumer, a type worth enforcing, etc).

## Two conditional-evaluation traps hit while wiring this in — read before writing `config = if ...` or `attrs // optionalAttrs cond {...}` in a module shared across hosts

**Trap: a module's own top-level `config` can't be a bare `if` between
differently-shaped attrsets when the condition depends on another option in
the same fixpoint.** `modules/host/power/nixos.nix` originally had:

```nix
config = if isServer then server else if isLaptop then laptop else desktop;
```

where `isServer`/`isLaptop` came from `config.host.isServer`/`isLaptop`. This
produced `infinite recursion encountered`, reported as "while evaluating the
module argument `config`" in this exact file. NixOS's module merge needs to
know, for every module, the *set of top-level keys* it contributes — a
literal attrset's keys are visible without evaluating anything, but a raw
`if` between differently-shaped branches (here: `server` has an extra
`systemd.targets` key that `desktop` lacks) can't be inspected without first
evaluating the condition. Evaluating `config.host.isServer` requires the
overall `config` to progress — the same `config` this very module's own
`config` attribute is contributing to. Fix: `lib.mkMerge [ (lib.mkIf isServer
server) (lib.mkIf (isLaptop && !isServer) laptop) (lib.mkIf (!isServer &&
!isLaptop) desktop) ]` — `mkIf`'s key set is fixed by its syntactic position
(the attribute name it's assigned to), not by evaluating the condition.

**Trap: `lib.optionalAttrs`/`//` have exactly the same problem `lib.mkIf`
does *not* have, when the condition comes from `config.*` instead of a
specialArg.** `home-manager` (the option) needs to not exist at all for a
host lacking `tools.homeManager.enable` — that option isn't even declared
there, since the flake-input home-manager module is only injected for that
setting (see the next section). Contributing it via
`// lib.optionalAttrs config.host.tools.homeManager.enable {...}` inside a
module also declaring `options.host` hits the identical "must evaluate the
condition to know the contributed key set, but the condition needs this same
config" cycle as the `if` trap above (`optionalAttrs cond {...}` is itself
sugar for `if cond then attrs else {}`). The eventual fix was better than
patching the condition: **conditionally *import* `modules/host/home-manager/`
itself** (`lib.optional host.tools.homeManager.enable ./home-manager`, using
the `host` specialArg — pre-fixpoint, no dependency on this module's own
config), the same mechanism already used for `isLinux`/`isDarwin`-gated
topic modules. A conditionally-imported *file* either contributes its whole
module or doesn't exist in the `modules` list at all — no partial-attrs
merge trick needed, and the option-doesn't-exist-at-all problem simply can't
arise since the file declaring `config.home-manager` is never evaluated for
a host that doesn't enable it. `modules/host/openssh/` hit the same shape
from a different angle — a single shared file with
`mkIf host.isLinux { services.fail2ban = ...; }` still errored
("`services.fail2ban` does not exist") when built for darwin, because
`services.fail2ban` isn't declared there *at all* and `mkIf false` still
registers the path (trap #1 from the original schema-wiring session, still
true). Turned out nix-darwin's `services.openssh` is minimal enough
(`enable` + raw `extraConfig` text only — no `.settings`, no
`openFirewall`, no fail2ban) that guessing a shared shape wasn't worth it at
all — `openssh/nixos.nix` and `openssh/darwin.nix` are now two separate
files, each targeting its own platform's real option shape.

**The general rule this leaves us with**: reference a `config.*`-derived
condition freely *inside* `mkIf`/`mkMerge` values (that's the whole point of
those functions — lazy, no key-set inspection needed), but never as the
condition deciding *whether a key exists at all* (`if`, `optionalAttrs`, bare
`//`) in a module whose own `config` output contributes to the very thing
being conditioned on. For that, reach for the `host` specialArg instead —
it's plain pre-fixpoint data with no such dependency, the same reasoning
already established for platform-detection booleans (see the next section).

## Three earlier evaluation traps — still true, now under the `host.*` namespace

1. **A `false` `lib.mkIf` does not protect a reference to an option that
   isn't declared for that host at all.** `documentation.nixos.enable`
   doesn't exist on nix-darwin; `services.fail2ban.*` doesn't exist on
   darwin either (see the openssh example above); the `home-manager` option
   itself doesn't exist unless `inputs.home-manager.{nixosModules,darwinModules}.default`
   was actually injected for that host. **`nix flake check` does not force
   deep enough to catch this** — what catches it is forcing
   `config.system.build.toplevel.drvPath` for every host, the standard
   verification step any time a module shared across hosts with different
   capabilities changes.

2. **A platform-detection boolean used inside a module that also sets
   `nixpkgs.config`/`nixpkgs.overlays` must come from the `host` specialArg**,
   not `pkgs.stdenv.isLinux`, the `system` special arg, or `_module.args` set
   from within a host module — all three of the latter are themselves derived
   from `config.nixpkgs.*`/`config._module.args`, so a module that both reads
   one of them *and* contributes to `nixpkgs.config`/`overlays` hits
   `infinite recursion encountered`. `modules/host/nix/default.nix` (which
   sets `nixpkgs.config.allowUnfree`, `permittedInsecurePackages`, and the
   `mylib` overlay) uses `host.isLinux` for exactly this reason.

3. **Once the platform flag is a true specialArg value, `{...} //
   lib.optionalAttrs host.isLinux {...}` at a module's own outermost `config`
   works correctly** — `modules/host/nix/default.nix` uses exactly this
   pattern for `documentation.nixos.enable`. This is safe specifically
   *because* the condition (`host.isLinux`) carries no dependency on this
   module's own contribution to `config` — see the two traps above for what
   happens when the condition isn't specialArg-safe.

## `disk/`: type/fileSystem/disko.devices.disk are all asserted, autoScrub/fstrim/smartd inferred as `mkDefault`

Every Linux host now expresses its disk topology through `host.hardware.disk.*`
— `pangolin`'s used to live in a hand-written `hosts/pangolin/base/disk/default.nix`
that pre-dated this design, but that directory doesn't exist anymore and its
whole topology (including the `@ @home @nix @var @snapshots` subvolume set)
is inlined directly into `host.hardware.disk.disko.devices.disk` in
`hosts/pangolin/default.nix`, matching pc's existing style. `disk/nixos.nix`
asserts `disk.type`, `disk.fileSystem`, and `disk.disko.devices.disk` are all
set — a Linux host can no longer silently ship with no disk topology at all.
The inferred `services.{btrfs.autoScrub,fstrim,smartd}.*` settings (derived
from `disk.type`/`fileSystem`) still use `lib.mkDefault` rather than a plain
assignment, since a host can have real hardware reasons to override them.
`smartd` specifically is also derived from `host.isQemu` (`type` includes
`"qemu"`, alongside desktop/laptop/server/workstation — a host can be e.g.
`["server" "qemu"]` simultaneously, same list-not-enum reasoning as the rest
of `host.type`): QEMU/KVM virtual disks have no SMART passthrough at all
("IE (SMART) not enabled, skip device"), so `smartd.enable` defaults to
`!isQemu`. pangolin sets `type = [ "server" "qemu" ];` and no longer needs a
hand-written `services.smartd.enable = false;` override at all — this used
to be exactly that hand-written override, moved into the shared module once
a second QEMU-hosted machine looked plausible enough to be worth naming as a
`host.type` value rather than staying a one-off.

Disko itself is injected unconditionally for every Linux host by
`lib/mkConfigurations.nix` — not gated on a capability at all anymore (see
the "`capabilities` removed" section above) — so this assertion is the only
thing standing between "forgot to configure a disk" and a host that fails to
install with a confusing disko error instead of a clear one naming the host
and field.

## `networking`/`locale`/`user`: cross-platform pairs, one shared field per concern

Each of these owns a `{nixos,darwin}.nix` pair reading the same
`host.environment.*` fields — `host.environment.locale.{timeZone,keyboard,language.*}`,
`host.environment.networking.{interface,dns,networkd.*}` (`interface` is the
*one* "which interface" field a host declares — reused both as the
networkmanager MAC-randomization target on nixos and as the
`systemd.network.networks."10-wan".matchConfig.Name` on the static-networkd
path), and `host.environment.user.{username,fullName,
wheelNeedsPassword,sshKeys}`. `networking/nixos.nix` asserts `interface` is
set and `networkd.static.addresses` is non-empty whenever
`networkd.enable = true` — a host can't flip on static networkd and forget
to give it an address or a match interface.

`isServer`/`isLaptop` (used by `power/nixos.nix` for the server/laptop/desktop
three-way split, and by `networking/nixos.nix` for MAC-randomization policy)
are the `config.host.isServer`/`isLaptop` **derived booleans**, not
`config.host.type == "server"` — `host.type` is a `listOf enum`
(`["desktop" "workstation" "server"]` for pc, which is legitimately both a
desktop *and* a server), so comparing it directly to a bare string is always
false. This was an actual bug caught while migrating these two files onto the
new namespace, not a hypothetical.

`description = if fullName != null then fullName else username;` in both
`user/nixos.nix` and `user/darwin.nix` — not `description = fullName;` — for
the same reason documented in the schema-wiring session: `fullName`'s
declared `default = null;` means the field always exists once validated, so
a host that never sets it (pangolin) gets `null`, not an absent attribute,
and `users.users.<name>.description` requires a string.

## `boot/`: standardized on grub, with recommended defaults so hosts need zero overrides

`modules/host/boot/nixos.nix` picks grub for every NixOS host. No `.enable`
— every NixOS host needs a working bootloader, no valid "off" state.
`host.hardware.boot.efiSupport` has no default — every host must declare its actual
firmware mode explicitly, since there's no reliable way to autodetect a
remote/cross-built host's firmware at eval time. Recommended defaults
(`kernelParams = ["quiet" "splash"]`, a broad SATA/NVMe/USB/virtio
`availableKernelModules` union, `wait-online.enable = false`,
`services.fwupd.enable = true`) mean pc/pangolin need zero host-level boot
overrides beyond `efiSupport` itself.

## `cpu`/`gpu`: option-driven, not enable-gated — but a value is required, via assertion

`host.hardware.cpu`/`host.hardware.gpu` are `nullOr (enum [...])` rather than `.enable`-gated —
every real Linux host has *some* CPU, and most have a GPU worth configuring,
so there's no meaningful "off" state, just "which one." `null` is only the
type-level default so the schema doesn't force a value at parse time; both
`cpu/nixos.nix` and `gpu/nixos.nix` assert the resolved value is non-null,
since a Linux host silently missing either would previously fail with a
cryptic "attribute 'null' missing" (from indexing `gpuPackages.${gpu}` etc.)
instead of a message naming the host and field. Each switches
`boot.kernelModules`/`hardware.*`/`environment.variables` internally.
`nvtop` was renamed upstream to `nvtopPackages.<vendor>`/`nvtopPackages.full`
— `gpu/nixos.nix`'s shared tool list (not vendor-specific) uses
`nvtopPackages.full` accordingly.

`gpu == "intel"` always adds `i915.enable_guc=3` to `boot.kernelParams` (used
to be a one-off `boot.kernelParams` line hand-written in `hosts/pangolin`'s
own `module` block — now automatic for any host with `gpu = "intel"`, and
removed from pangolin's file). `host.hardware.gpuForceProbeId` (`nullOr str`, default
`null`) is the intel-specific analogue of `legacyGPU` on AMD — some iGPUs
newer than what the running kernel's i915 natively recognizes (e.g. Alder
Lake at release) need their PCI device ID force-probed to light up at all;
setting it adds `i915.force_probe=<id>` on top of `enable_guc=3`. It's a
string, not a bool, since the value itself (the device ID) has to come from
the host, unlike `legacyGPU` which needs no extra data.

## Dangling `hosts/<name>/base` imports found and removed this session

`hosts/pangolin/default.nix` and `hosts/mac/default.nix` both still did
`imports = [ ./base ];` in their `module` block, but neither
`hosts/pangolin/base/` nor `hosts/mac/base/` exist anymore — both were fully
emptied out in earlier sessions (pangolin's disk topology inlined into
`host.disk.disko`, mac's `display`/`homebrew`/`locale`/`network`/`nix`/`user`/
`power` all migrated into `modules/darwin`/`modules/host/<topic>/darwin.nix`
at the time — `modules/darwin` itself was later retired too, see the section
below) without the now-dead `imports` line being removed. `nix flake check` didn't
catch either: it doesn't force `nixosConfigurations.pangolin` deep enough to
hit a plain `./base` path that doesn't exist unless something inside actually
forces it, and it's shallower still for `darwinConfigurations` (see the
"Verification" section below). Only forcing
`config.system.build.toplevel.drvPath` for each host surfaced both. mac's
`base/system/` (dock/finder/trackpad/NSGlobalDomain personal-taste prefs) was
never migrated anywhere before being deleted — confirmed with the user this
was fine to just drop the dangling import rather than reconstruct it from
nothing (no VCS history to recover the original values from).

The original `modules/nixos/lib/btrfs-root-subvolumes.nix` helper (a plain
function producing the standard `@ @home @nix @var @snapshots` subvolume set)
no longer exists either — deleted along with `modules/nixos` in an earlier
pivot. Its one remaining caller, pangolin, now has its subvolumes inlined
directly in `hosts/pangolin/default.nix`'s `host.hardware.disk.disko`,
matching pc's existing style (pc's own disko config was always inline,
predating the helper). If a third host ever needs the same five-subvolume
shape, reconsider extracting a shared function then.

## `modules/darwin` retired — MonitorControl folded into `power/darwin.nix`, gated on `host.hardware.display`

`modules/darwin/` only ever held one thing (`display/`, the MonitorControl
wiring) once homebrew was removed — not worth its own darwin-only tree for a
single file, and it sat oddly separate from `power/darwin.nix` (also
display/hardware-adjacent: Battery Toolkit, pmset). Moved MonitorControl's
config into `power/darwin.nix` as a third `lib.mkMerge` branch, gated on a
`host.hardware.display` bool (`lib/hostSchema.nix`, same plain-bool pattern
as `host.hardware.audio`/`bluetooth` — darwin-only in practice, just stays
`false` on Linux hosts the way `cpu`/`gpu` stay `null` on mac). This also
retired the last `custom.*`-namespaced option left in the repo
(`custom.display.enable` — everything else had already migrated to `host.*`
in earlier sessions; this one was simply the one file that hadn't been
touched since). `lib/mkConfigurations.nix`'s `../modules/darwin` injection
is gone along with the directory. mac's `module` block is now a bare `{ }`
— `host.hardware.display =
true;` moved into its `host` data block instead, alongside the rest of mac's
per-host settings.

- Disko device topology and GPU/CPU vendor *package lists* stay per-host —
  genuinely hardware-specific, not duplicated.
- mac's dock/finder/trackpad/NSGlobalDomain personal-taste prefs — used to
  live in `hosts/mac/base/system/`, but that directory (and the rest of
  `hosts/mac/base/`) is gone; see the dangling-imports section above. Nothing
  currently manages these on mac.
- `environment.systemPackages` in `hosts/pc/default.nix` +
  `hosts/mac/default.nix` overlaps with `home.packages` in
  `homes/dami/shell/core/` (curlMinimal, wget, rsync, ffmpeg, gitMinimal,
  pciutils, usbutils appear in both). That's a system-vs-user-layer overlap,
  not same-file duplication, and removing it changes what's available to
  `root` — a behavior call left to a separate decision, not folded into this
  cleanup.

## Verification

Same discipline throughout: `nix flake check`, then forcing
`config.system.build.toplevel.drvPath` for every host
(`nixosConfigurations.pc`/`.pangolin`, `darwinConfigurations.mac`) — `flake
check` alone missed every trap documented above (dangling module paths,
undeclared-option references under `mkIf false`, the two conditional-key-set
recursions, a plain type mismatch on a `null` locale field), and only
force-evaluating each host's real derivation surfaced them one at a time.
Spot-checked representative resolved values afterward (pipewire/grub/gnome
enable on pc, static networkd addresses and autoScrub interval on pangolin,
homebrew/display/LANG on mac, confirming pangolin genuinely has no
`home-manager` option at all) to confirm the migration preserved intent, not
just that it evaluates.

**GPU/networking/capabilities/assertions session**: same discipline, plus
deliberately triggering every new assertion/type-error in a throwaway `/tmp`
copy before trusting it (matching this repo's standing verification
convention) — `host.gpu = null` on pc, `host.disk.type = null` on pc, empty
`networking.networkd.static.addresses` on pangolin, and an unknown
`capabilities.agenix` key on mac all failed with the intended message, not a
generic Nix error. Spot-checked resolved values: pc's `boot.kernelParams`
carries the amd-legacy params (no intel ones); pangolin's carries
`i915.enable_guc=3` automatically (previously hand-written, now derived from
`gpu == "intel"`, matching the value that was there before byte-for-byte);
pangolin's `disko.devices.disk` resolves non-empty; pc's
`networking.firewall.interfaces` is keyed by `"eno1"` (via
`host.networking.interface`, through jellyfin's firewall rule); pc's
`environment.systemPackages` includes the agenix CLI package with no
`capabilities.agenix` flag set anywhere. The two dangling `./base` imports
(pangolin, mac) were found incidentally while force-evaluating
`system.build.toplevel.drvPath` for this work, not part of what was asked —
see the dedicated section above for what each contained and how they were
resolved.

**`hardware`/`environment`/`tools` reorganization session**: `nix flake
check` passed clean on the first attempt despite the scope (every
`modules/host/<topic>` consumer, all three host files, `secrets.nix`,
`lib/mkConfigurations.nix`, plus every `hosts/pc/services/**`/`hosts/pc/gaming/**`
leaf config reading the `host` specialArg). `system.build.toplevel.drvPath`:
pangolin came back byte-identical (pure rename, zero logic change); pc and
mac both shifted — expected and investigated, not waved off: pc's shift
traces to `hermesAgent` moving from a central `capabilities`-gated list
entry to a direct import inside pc's own `module.imports` (a real
list-construction-order change even though the resolved config is
identical — confirmed `services.hermes-agent.enable == true` post-change);
mac's shift traces to schema field reordering inside `lib/hostSchema.nix`
itself rippling into the derivation despite no resolved leaf value actually
changing (confirmed via spot-checks: `host.hardware.display`,
`host.tools.homeManager.enable`, `host.environment.locale.language.lcTime`,
and the live `environment.variables.LC_TIME` all matched pre-change values
exactly). `secrets.nix` re-verified after the `sshKeys`→`publicKey` field
rename: all 6 `.age` files still resolve to exactly 2 recipients each, and
both new failure modes (`host.tools.agenix.publicKey` unset,
`host.tools.agenix.enable = false` while still owning a secret) were
deliberately triggered in a throwaway copy and produced the intended
host-naming error text before being trusted. Real `nixos-rebuild build`
(not just eval) run on both pc and pangolin as a final check — pangolin's
build reused every cached path (0 copied, byte-identical output), pc's
rebuilt cleanly with the new module-import shape.
