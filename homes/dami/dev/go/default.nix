{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    air
    gopls
    gofumpt
    delve
    golangci-lint
    golangci-lint-langserver
  ];

  programs = {
    go = {
      enable = true;
      telemetry.mode = "off";
      env.GOPATH = "${config.home.homeDirectory}/Developer/.go";
    };

    zed-editor = {
      extensions = [ "golangci-lint" ];
      userSettings = {
        languages.Go.language_servers = [
          "gopls"
          "golangci-lint"
        ];
        lsp = {
          gopls = {
            binary = {
              path = lib.getExe pkgs.gopls;
              arguments = [ "serve" ];
            };
            initialization_options.gofumpt = true;
          };
          "golangci-lint".initialization_options.command = [
            "golangci-lint"
            "run"
            "--output.json.path"
            "stdout"
            "--show-stats=false"
            "--output.text.path="
          ];
        };
      };
    };

    claude-code = {
      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "samber";
          repo = "cc-skills-golang";
          rev = "466ea6dfd4aecb5c19caf29e7595e752c66c1a5d";
          hash = "sha256-+NLRtVyE8XbpVGhIrKqT1cB+9+lejlMat30iRX1m0YE=";
        })
      ];

      rules.go = ''
        - Formatter: gofumpt (stricter gofmt) — never suggest plain `gofmt`
        - Linter: golangci-lint — config file is `.golangci.yml`; run `golangci-lint run` before considering a change done
        - Debugger: delve (`dlv`) — e.g. `dlv debug ./cmd/foo`
        - Hot reload: air — config file is `.air.toml`
        - LSP: gopls, configured with `gofumpt = true` — trust its diagnostics over manual formatting
        - GOPATH is `~/Developer/.go` (set via `programs.go.env.GOPATH`), not the Go default `~/go` — don't assume the default when locating installed binaries or module caches
        - Telemetry is off (`telemetry.mode = "off"`) — don't re-enable it or run `go telemetry on`
        - Helix gets the same gopls + golangci-lint-lsp wiring as Zed for free (Helix's own upstream defaults already reference both by name); only the `golangci-lint-langserver` binary needed adding here
      '';
    };
  };
}
