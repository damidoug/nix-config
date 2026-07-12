{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [ biome ];

  programs = {
    bun = {
      enable = true;
      settings = {
        smol = true;
        telemetry = false;
      };
    };

    zed-editor = {
      extensions = [
        "astro"
        "biome"
        "vue"
        "svelte"
      ];
      userSettings = {
        languages =
          let
            biomeLanguage = {
              formatter.language_server.name = "biome";
              code_actions_on_format = {
                "source.fixAll.biome" = true;
                "source.organizeImports.biome" = true;
              };
              preferred_line_length = 80;
            };
          in
          {
            Astro = biomeLanguage;
            CSS = biomeLanguage;
            GraphQL = biomeLanguage;
            HTML = biomeLanguage;
            JSON = biomeLanguage;
            JSONC = biomeLanguage;
            JSX = biomeLanguage;
            JavaScript = biomeLanguage;
            Svelte = biomeLanguage;
            TSX = biomeLanguage;
            TypeScript = biomeLanguage;
            "Vue.js" = biomeLanguage;
          };
        lsp.biome = {
          binary = {
            path = lib.getExe pkgs.biome;
            arguments = [ "lsp-proxy" ];
          };
          settings.require_config_file = false;
        };
      };
    };

    helix.languages.language =
      map
        (name: {
          inherit name;
          auto-format = true;
          language-servers = [ "biome-lsp-proxy" ];
        })
        [
          "javascript"
          "jsx"
          "typescript"
          "tsx"
          "json"
          "jsonc"
          "css"
          "html"
          "graphql"
          "vue"
          "svelte"
          "astro"
        ];

    claude-code.rules.js = ''
      - Runtime + package manager: bun — NOT node/npm/yarn/pnpm; use `bun install`, `bun run`, `bun test`, `bun add`
      - `smol = true` — bun runs in low-memory mode; don't be surprised by slightly slower startup, it's intentional
      - Formatter + linter: biome — NOT prettier/eslint; don't add prettier/eslint config files, biome covers JS/TS/JSX/TSX/JSON/CSS/HTML/GraphQL/Astro/Svelte/Vue
      - `require_config_file = false` — biome works without a `biome.json`, but add one if project-specific rules are needed
      - Format-on-save runs biome's fix-all + organize-imports — don't manually reorder imports in these file types
      - LSP: biome (`biome lsp-proxy`)
      - Zed wraps these languages at column 80, matching biome's default `lineWidth` (not overridden here)
      - Helix auto-formats the same language set on save via biome's LSP (`biome-lsp-proxy`, a Helix built-in) — typescript-language-server is NOT installed, so don't expect TS type-intelligence in Helix, only biome's diagnostics/formatting
    '';
  };
}
