{ pkgs, lib, ... }:
let
  # single source of truth for ruff's line-length — reused for Zed's wrap
  # column below so the editor's wrap guide always matches the formatter
  ruffLineLength = 100;
in
{
  home.packages = with pkgs; [ python314 ];

  programs = {
    uv = {
      enable = true;
      settings = {
        python-downloads = "never";
        python-preference = "only-system";
      };
    };

    ruff = {
      enable = true;
      settings = {
        line-length = ruffLineLength;
        per-file-ignores."__init__.py" = [ "F401" ];
        lint = {
          select = [
            "E4"
            "E7"
            "E9"
            "F"
            "I"
          ];
          ignore = [ ];
        };
      };
    };

    ty.enable = true;

    zed-editor.userSettings = {
      languages.Python = {
        language_servers = [
          "ty"
          "!basedpyright"
          "..."
        ];
        code_actions_on_format = {
          "source.organizeImports.ruff" = true;
          "source.fixAll.ruff" = true;
        };
        preferred_line_length = ruffLineLength;
      };
      lsp = {
        ty.binary = {
          path = lib.getExe pkgs.ty;
          arguments = [ "server" ];
        };
        ruff.binary = {
          path = lib.getExe pkgs.ruff;
          arguments = [ "server" ];
        };
      };
    };

    helix.languages.language = [
      {
        name = "python";
        auto-format = true;
        language-servers = [
          "ty"
          {
            name = "ruff";
            only-features = [
              "format"
              "code-action"
            ];
          }
        ];
      }
    ];

    claude-code.rules.python = ''
      - Runtime: python 3.14 (`python314`) — installed as a system/home package, not via uv
      - Package/env manager: uv — NOT pip, virtualenv, pyenv, or conda; use `uv add`, `uv run`, `uv sync`, `uv venv`
      - `python-downloads = "never"` and `python-preference = "only-system"` — uv will NOT download its own Python interpreters; if a project pins a Python version not installed on this system, uv sync will fail rather than fetch it — install the version via Nix instead of expecting uv to fetch it
      - Formatter + linter: ruff, config is `programs.ruff` here (single source of truth, line-length 100, rules E4/E7/E9/F/I) — don't hand-edit `~/.config/ruff/ruff.toml`, it's generated
      - Type checker: ty (not mypy/pyright) — `ty check`
      - LSP: ty + ruff — basedpyright is explicitly disabled in Zed (`"!basedpyright"`)
      - Format-on-save runs `ruff` organize-imports and fix-all — don't manually reorder imports or fix trivial lint issues by hand, ruff already does it
      - Zed wraps Python at column 100, matching ruff's line-length exactly
      - Helix auto-formats python on save too; ruff there is scoped to format/code-action only so it doesn't duplicate ty's diagnostics
    '';
  };
}
