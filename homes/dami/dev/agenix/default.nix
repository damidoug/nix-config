{ pkgs, inputs, ... }:
{
  home.packages = [ inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default ];

  # agenix's own CLI resolves `secrets.nix` relative to CWD (no upward
  # search like git/jj), and the FILE argument to `-e`/`-d` doubles as both
  # the filesystem path *and* the lookup key into secrets.nix's returned
  # attrset — so both only line up when invoked from the repo root. This
  # wrapper finds the nearest ancestor directory containing secrets.nix,
  # rewrites the FILE argument to be relative to *that* directory, and runs
  # the real `agenix` from there — letting `agenix -e some/local/secret.age`
  # work from any subdirectory, not just the repo root. `--rekey`/`-h`/etc
  # pass through unchanged (no FILE argument to rewrite), just relocated to
  # run from the repo root too.
  programs.fish.functions.agenix = ''
    set -l dir $PWD
    while test $dir != / && not test -f $dir/secrets.nix
      set dir (dirname $dir)
    end
    if not test -f $dir/secrets.nix
      echo "agenix: no secrets.nix found in $PWD or any parent directory" >&2
      return 1
    end

    set -l args $argv
    if test (count $argv) -ge 2
      switch $argv[1]
        case -e --edit -d --decrypt
          set -l file $argv[2]
          if not string match -q '/*' -- $file
            set file $PWD/$file
          end
          set args[2] (string replace -- (realpath $dir)/ "" (realpath $file))
      end
    end

    pushd $dir >/dev/null
    command agenix $args
    set -l code $status
    popd >/dev/null
    return $code
  '';

  programs.claude-code.rules.agenix = ''
    - Secrets are age-encrypted `.age` files, managed with `agenix` — edit with `agenix -e <file>.age`, never decrypt/hand-edit manually. A fish wrapper (this module) lets that path be relative to your CWD, not just the repo root
    - Which hosts can decrypt which secrets is controlled by `secrets.nix` at the repo root — auto-scoped per host from `host.tools.agenix.publicKey` (lib/hostSchema.nix), not a single global key list; a host only decrypts secrets it actually owns (inferred by path: `hosts/<name>/**`)
    - Secrets live next to the service that uses them (e.g. `hosts/pc/services/.../secrets.age`), not centralized in one directory
    - Never commit a decrypted secret or print one to the terminal
  '';
}
