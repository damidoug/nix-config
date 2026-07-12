{ pkgs, lib, ... }:
{
  home.packages =
    (with pkgs; [
      cargo
      clippy
      rustc
      rustfmt
      rust-analyzer
      cargo-nextest
    ])
    ++ [
      # unstable's rust/clang toolchain currently fails to link cargo-watch on
      # aarch64-darwin (ld crashes) — pkgs.stable has a working prebuilt one.
      pkgs.stable.cargo-watch
    ];

  programs = {
    zed-editor.userSettings = {
      languages.Rust = {
        formatter.language_server.name = "rust-analyzer";
        code_actions_on_format = {
          "source.fixAll.rust-analyzer" = true;
          "source.organizeImports.rust-analyzer" = true;
        };
        preferred_line_length = 100;
      };
      lsp.rust-analyzer = {
        binary = {
          path = lib.getExe pkgs.rust-analyzer;
          arguments = [ ];
        };
        settings = {
          checkOnSave.command = lib.getExe pkgs.clippy;
          diagnostics.enable = true;
          cargo.loadOutDirsFromCheck = true;
          rustfmt.extraArgs = [
            "--edition"
            "2021"
          ];
          rustfmt.overrideCommand = [ "${lib.getExe pkgs.rustfmt}" ];
        };
      };
    };

    helix.languages.language-server.rust-analyzer.config = {
      checkOnSave.command = lib.getExe pkgs.clippy;
      cargo.loadOutDirsFromCheck = true;
      rustfmt.extraArgs = [
        "--edition"
        "2021"
      ];
      rustfmt.overrideCommand = [ (lib.getExe pkgs.rustfmt) ];
    };

    claude-code.rules.rust = ''
      - Formatter: rustfmt, edition 2021 — don't pass `--edition 2024`/`2018`, this config is pinned to 2021
      - Linter: clippy — rust-analyzer's check-on-save runs clippy instead of plain `cargo check`, so `cargo clippy` output is the one that matters, not `cargo build` warnings alone
      - Tests: `cargo nextest run` — NOT `cargo test` (nextest is installed and is the expected test runner)
      - Dev loop: `cargo watch -x run` (cargo-watch installed) for auto-rebuild on save
      - LSP: rust-analyzer, `cargo.loadOutDirsFromCheck = true` — build-script-generated code is picked up automatically, don't manually trigger a rebuild just to refresh analyzer state
      - Zed wraps Rust at column 100, matching rustfmt's default `max_width` (not overridden here)
      - Helix gets the same rust-analyzer checkOnSave=clippy / rustfmt tuning as Zed — one set of values, two editors
    '';
  };
}
