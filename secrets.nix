# Every .age file anywhere in the repo is auto-discovered (findAgeFiles) and
# scoped to editorKeys ++ [ the owning host's tools.agenix.publicKey ] —
# never to every host in the repo. Ownership is inferred purely from path: a
# file under hosts/<name>/** is owned by <name>, whose key comes from that
# host's own `host.tools.agenix.publicKey` (lib/hostSchema.nix — see
# modules/README.md's `host.tools.agenix` section for why this is a real
# schema field rather than an ad-hoc host.extra value). Fixes the previous
# design, where every secret was encrypted for every host's SSH host key
# regardless of which host actually used it.
#
# agenix's CLI does a plain `import ./secrets.nix` (confirmed against the
# pinned agenix source) — only `builtins` is available here, no `pkgs`/`lib`.
# Host data is read as plain, unvalidated attrsets (same raw `import
# ../hosts/${name}` pattern lib/mkConfigurations.nix itself uses
# pre-fixpoint) — the `or null` fallback below replicates
# lib/hostSchema.nix's own default for host.tools.agenix.publicKey by hand,
# since this file never runs the real schema validation.
let
  # Personal keys of humans allowed to run `agenix -e`/`-d` interactively —
  # not tied to any host's activation-time decryption. Add more entries here
  # if a second operator ever needs edit access to every secret.
  dami = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30CYuB+7IA5hfsYCUadhnyycrhR6+kWCDyDi8DkYk+ dami@macbook-air";
  editorKeys = [ dami ];

  # Mirrors lib/mkConfigurations.nix's own hostNames pattern (any hosts/<name>/
  # directory containing a default.nix is a real host) so host enumeration
  # is never hardcoded in two places.
  hostsDir = ./hosts;

  hostNames = builtins.filter (
    name:
    (builtins.readDir hostsDir).${name} == "directory"
    && builtins.pathExists (hostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  hostFiles = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = import (hostsDir + "/${name}");
    }) hostNames
  );

  findAgeFiles =
    baseDir: relPath:
    let
      fullPath = baseDir + "/${relPath}";
      contents = builtins.readDir fullPath;
      list = builtins.mapAttrs (
        name: type:
        let
          newRelPath = if relPath == "." then name else "${relPath}/${name}";
        in
        if type == "directory" then
          if builtins.substring 0 1 name == "." then [ ] else findAgeFiles baseDir newRelPath
        else if type == "regular" && builtins.match ".*\\.age$" name != null then
          [ newRelPath ]
        else
          [ ]
      ) contents;
    in
    builtins.concatLists (builtins.attrValues list);

  ageFiles = findAgeFiles ./. ".";

  hasPrefix = prefix: str: builtins.substring 0 (builtins.stringLength prefix) str == prefix;

  # Single-owner model only — no current secret is shared across hosts. If a
  # genuinely multi-host secret ever shows up, extend this to also check an
  # optional `host.extra.agenixSharedWith = [ "otherhost" ]` list on the
  # owning host and append those hosts' keys too — not built now, zero
  # current demand for it.
  ownerKeyForFile =
    path:
    let
      matches = builtins.filter (name: hasPrefix "hosts/${name}/" path) hostNames;
    in
    if matches == [ ] then
      throw ''
        secrets.nix: '${path}' is not under any known hosts/<name>/ directory.
        Every .age file must be owned by exactly one host so it can be
        scoped to that host's own key. Move it under hosts/<name>/.''
    else
      let
        owner = builtins.head matches;
        ownerHost = hostFiles.${owner}.host;
        key = ownerHost.tools.agenix.publicKey or null;
      in
      # A host that owns a secret must have tools.agenix.enable = true (so
      # the `age.secrets` module is actually injected for it — see
      # lib/mkConfigurations.nix's `assertHost`, which already requires
      # publicKey whenever enable is true) — not re-checked here, this just
      # reads whatever publicKey ended up set.
      if key == null then
        throw ''
          secrets.nix: '${path}' is owned by host '${owner}', but
          hosts/${owner}/default.nix has no host.tools.agenix.publicKey set.
          Add that host's own SSH host public key
          (cat /etc/ssh/ssh_host_ed25519_key.pub on ${owner}) first.''
      else
        key;
in
builtins.listToAttrs (
  map (path: {
    name = path;
    value = {
      publicKeys = editorKeys ++ [ (ownerKeyForFile path) ];
    };
  }) ageFiles
)
