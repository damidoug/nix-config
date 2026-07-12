{ pkgs, ... }:
{
  home.packages = with pkgs; [
    sqlite
    sqlx-cli
    supabase-cli
  ];

  programs = {
    zed-editor.extensions = [ "sql" ];

    claude-code = {
      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "supabase";
          repo = "agent-skills";
          rev = "1356046015476711a769601079262b5635929427";
          hash = "sha256-QFsXvpZ5BrNK17ibb2KfSz1Z4VtsBuR8W/Hx9MTRycQ=";
        })
      ];

      rules.sql = ''
        - Primary local/embedded DB: SQLite — CLI is `sqlite3`
        - Rust DB layer + migrations: sqlx-cli — `sqlx migrate run`, `sqlx migrate add <name>`; never hand-write migration state, let sqlx track it
        - Supabase CLI (`supabase`) is for hosted Postgres/Supabase projects — `supabase start`, `supabase db diff`, `supabase migration new`; this is a separate workflow from the sqlite/sqlx one above, don't mix the two up
        - Supabase projects are Postgres, not SQLite — don't assume SQLite syntax/types apply
      '';
    };
  };
}
