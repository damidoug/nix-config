{ ... }:
{
  programs = {
    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        telemetry = "disabled";
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "damidoug";
          email = "contact@damidoug.dev";
        };
        ui = {
          default-command = "log";
        };
        git.auto-local-bookmark = true;
      };
    };

    zed-editor.extensions = [ "git-firefly" ];

    claude-code.rules.vcs = ''
      - VCS is jujutsu (jj), NOT git — never run `git commit`, `git branch`, `git log`, `git push`, `git checkout`, etc.
      - jj has no staging area — there is nothing to `jj add`; the whole working copy is always part of the current change
      - Everyday commands: `jj` (bare, aliased to `jj log`), `jj status`, `jj diff`, `jj new` (start the next change), `jj describe -m "..."` (message the current change), `jj commit -m "..."` (= describe + new)
      - Push with `jj git push` — there is no bare `jj push`
      - Bookmarks (jj's equivalent of branches) do NOT auto-follow new commits — move one explicitly with `jj bookmark set <name>` or `jj bookmark move` before pushing
      - `git.auto-local-bookmark = true` only creates a local bookmark automatically when you check out a remote one; it doesn't move existing bookmarks forward
      - jj has no `ui.editor` override here, so `jj describe`/`jj split` fall back to `$EDITOR` (helix, set in `shell/helix/default.nix`)
      - The git backend is colocated (git-compatible storage) but is an implementation detail — never invoke `git` subcommands directly for history operations
      - `gh` (GitHub CLI) is fine for PRs/issues/releases — it doesn't touch commit history, so it doesn't conflict with the jj-only rule above
      - `gh` telemetry is disabled and uses ssh for git_protocol — don't switch it to https
    '';
  };
}
