# Builds nixosConfigurations/darwinConfigurations/homeConfigurations.
#
# NixOS/darwin hosts come from hosts/<name>/default.nix, which returns
# `{ host; module; }`: `host` is plain data read directly here (outside the
# module fixpoint — this is what lets it pick the builder/channel before any
# module evaluation starts), validated + enriched by lib/hostSchema.nix, then
# handed to every injected module (including `module` itself) as the `host`
# specialArg. modules/host is injected unconditionally for every host (see
# modules/README.md's trap #1 for the failure class this closes) rather than
# hand-imported per host, so a host's own `module.imports` can't forget it.
#
# Hosts are auto-detected (any hosts/<name>/ with a default.nix); standalone
# home-manager machines are auto-detected the same way under homes/<user>/
# machines/ — see lib/README.md for how the three builders relate.
{ inputs }:
let
  lib = inputs.nixpkgs.lib;

  hostNames = builtins.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (../hosts + "/${name}/default.nix")
    ) (builtins.readDir ../hosts)
  );

  hostFiles = lib.genAttrs hostNames (name: import ../hosts/${name});

  # lib.evalModules here is a self-contained, pre-fixpoint validation pass —
  # it never touches pkgs/nixpkgs.*, so using the flake's own top-level
  # `lib` (independent of any host's chosen channel) is safe. See
  # lib/hostSchema.nix's own header for why this must stay that way.
  validateHost =
    raw:
    (lib.evalModules {
      modules = [
        ./hostSchema.nix
        { config = raw; }
      ];
    }).config;

  hosts = lib.mapAttrs (_: f: validateHost f.host) hostFiles;

  channelInputs = {
    unstable = inputs.nixpkgs;
    stable = inputs.nixpkgs-stable;
    master = inputs.nixpkgs-master;
  };

  # nix-darwin's master branch pairs with nixpkgs (unstable) and
  # nixpkgs-master alike — only "stable" needs its own pinned branch, since
  # that's the one nix-darwin actually guarantees compatibility for (not just
  # "recommended", see the home-manager comment below and
  # flake.nix's own input comments).
  darwinInputs = {
    unstable = inputs.nix-darwin;
    stable = inputs.nix-darwin-stable;
    master = inputs.nix-darwin;
  };

  # Same shape as darwinInputs, but home-manager-stable is only *recommended*
  # for a stable host, not required — so unlike nix-darwin, a host can
  # override which one it gets via host.tools.homeManager.channel instead of
  # it being strictly derived from host.channel. `homeManagerChannel`
  # resolves that override (falling back to host.channel when unset, i.e.
  # "automatic").
  homeManagerInputs = {
    unstable = inputs.home-manager;
    stable = inputs.home-manager-stable;
    master = inputs.home-manager;
  };
  homeManagerChannel =
    host:
    if host.tools.homeManager.channel != null then host.tools.homeManager.channel else host.channel;

  # The agenix *module* (age.secrets, decrypt-at-activation) and its *CLI
  # package* are both gated on the single host.tools.agenix.enable flag — a
  # host that opts in is asserted (below) to also declare
  # host.tools.agenix.publicKey, since secrets.nix uses that key to scope
  # which secrets this host is allowed to decrypt; a host with the module but
  # no key could never actually decrypt anything it might later be given.
  # disko stays unconditional for every Linux host — no host can legitimately
  # opt out of having a disk topology. The disko.devices.disk non-empty check
  # lives in modules/host/disk/nixos.nix, alongside its sibling
  # disk.type/disk.fileSystem assertions.
  #
  # hermes-agent has no entry here at all — it used to be gated on
  # `host.capabilities.hermesAgent`, but that had exactly one consumer (pc)
  # and no shared mechanism was ever needed for it, so it's now a plain
  # direct import in hosts/pc/default.nix's own `module` block instead.
  extraModules =
    host:
    lib.optionals host.tools.agenix.enable [
      (if host.isLinux then inputs.agenix.nixosModules.default else inputs.agenix.darwinModules.default)
      { environment.systemPackages = [ inputs.agenix.packages.${host.system}.default ]; }
    ]
    ++ lib.optionals host.isLinux [
      inputs.disko.nixosModules.default
    ]
    ++ lib.optionals host.tools.homeManager.enable [
      (
        let
          hm = homeManagerInputs.${homeManagerChannel host};
        in
        if host.isLinux then hm.nixosModules.default else hm.darwinModules.default
      )
    ]
    ++ [ ../modules/host ];

  # Shared pre-fixpoint validation for both builders — a plain `assert`
  # chain (same mechanism lib/hostSchema.nix documents as unavailable to
  # itself, since this runs *after* hostSchema's own eval has already
  # produced `host`, so ordinary asserts are fine here).
  assertHost =
    host:
    assert lib.assertMsg (channelInputs ? ${host.channel})
      "host '${host.name}': unknown channel '${host.channel}' (expected one of ${toString (lib.attrNames channelInputs)})";
    assert lib.assertMsg (!host.tools.agenix.enable || host.tools.agenix.publicKey != null)
      "host '${host.name}': tools.agenix.enable is true but tools.agenix.publicKey is not set — set it to this host's SSH host public key (cat /etc/ssh/ssh_host_ed25519_key.pub).";
    host;

  mkNixos =
    name: host':
    let
      host = assertHost host';
    in
    channelInputs.${host.channel}.lib.nixosSystem {
      inherit (host) system;
      modules = extraModules host ++ [ hostFiles.${name}.module ];
      specialArgs = { inherit inputs host; };
    };

  mkDarwin =
    name: host':
    let
      host = assertHost host';
    in
    darwinInputs.${host.channel}.lib.darwinSystem {
      inherit (host) system;
      modules = extraModules host ++ [ hostFiles.${name}.module ];
      specialArgs = { inherit inputs host; };
    };

  # Standalone home-manager machines (e.g. a plain Ubuntu box with Nix +
  # home-manager, not owned by this flake at all — no boot/disk/agenix,
  # activated via `home-manager switch --flake .#<user>@<machine>`) — see
  # lib/README.md for the full design and homes/<user>/machines/ file shape.
  homeUsernames = builtins.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (../homes + "/${name}/machines")
    ) (builtins.readDir ../homes)
  );

  homeMachines = lib.concatMap (
    user:
    let
      machineDir = ../homes + "/${user}/machines";
      machineFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
        builtins.readDir machineDir
      );
    in
    map (fileName: {
      inherit user;
      machine = lib.removeSuffix ".nix" fileName;
      data = import (machineDir + "/${fileName}");
    }) (builtins.attrNames machineFiles)
  ) homeUsernames;

  mkHomeStandalone =
    {
      user,
      machine,
      data,
    }:
    let
      inherit (data) system;
      channel = data.channel or "unstable";
      stateVersion = data.stateVersion or "26.05";
      homeDirectory =
        data.homeDirectory or (if lib.hasSuffix "-linux" system then "/home/${user}" else "/Users/${user}");
      # Same shared config/overlays modules/host/nix injects for a real
      # NixOS/darwin host (mylib, pkgs.stable/unstable/master, allowUnfree,
      # the vesktop electron exception) — per-machine since it's a function
      # of `system`. See lib/nixpkgsConfig.nix's own header for why this is
      # factored out rather than redefined here.
      sharedNixpkgs = import ./nixpkgsConfig.nix { inherit inputs system; };
    in
    assert lib.assertMsg (channelInputs ? ${channel})
      "home '${user}@${machine}': unknown channel '${channel}' (expected one of ${toString (lib.attrNames channelInputs)})";
    homeManagerInputs.${channel}.lib.homeManagerConfiguration {
      pkgs = import channelInputs.${channel} {
        inherit system;
        inherit (sharedNixpkgs) config overlays;
      };
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ../homes/default.nix
      ]
      ++ lib.optional (builtins.pathExists (../homes + "/${user}")) (../homes + "/${user}")
      ++ [
        {
          home = {
            username = user;
            inherit homeDirectory stateVersion;
          };
        }
      ];
    };

  homeConfigurations = lib.listToAttrs (
    map (m: {
      name = "${m.user}@${m.machine}";
      value = mkHomeStandalone m;
    }) homeMachines
  );
in
{
  nixosConfigurations = lib.mapAttrs mkNixos (lib.filterAttrs (_: host: host.isLinux) hosts);
  darwinConfigurations = lib.mapAttrs mkDarwin (lib.filterAttrs (_: host: host.isDarwin) hosts);
  inherit homeConfigurations;
}
