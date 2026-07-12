{ pkgs, ... }:
{
  programs = {
    zed-editor = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then pkgs.mylib.zed else pkgs.zed;

      extensions = [
        "env"
        "fish"
        "graphql"
        "log"
        "make"
        "toml"
      ];

      userSettings = {
        telemetry.metrics = false;
        format_on_save = "on";

        # Zed defaults soft_wrap to "off" (no wrapping at all) — wrap at
        # preferred_line_length instead. 100 is the base/fallback column;
        # languages with a formatter that enforces a different width
        # (python/rust/js) override preferred_line_length in their own
        # dev/<tool> module to match their formatter exactly.
        soft_wrap = "preferred_line_length";
        preferred_line_length = 100;

        # relative line numbers default to "disabled" — enable them since
        # motions in this setup (helix) are relative-line-based
        relative_line_numbers = "enabled";

        # Zed's default buffer/terminal fonts aren't Nerd Fonts, so icon
        # glyphs (e.g. in starship.toml) render as tofu boxes. The font
        # itself is installed by shell/starship/default.nix — this just
        # points Zed at it. "Mono" variant, not the proportional one.
        buffer_font_family = "FiraCode Nerd Font Mono";
        terminal.font_family = "FiraCode Nerd Font Mono";
      };
    };

    aerospace.settings.mode.main.binding.alt-c = "exec-and-forget open -na 'Zed'";

    claude-code.rules."visual editor" = ''
      - GUI editor: Zed — open with `zed .` or alt-c in aerospace
      - Format-on-save is enabled globally; per-language formatter/LSP config lives in the matching `dev/<tool>` module (see homes/dami/dev/README.md), not all in one file
      - When adding a new language server or formatter, put it next to the packages for that language, not in `dev/zed/default.nix`
      - Soft wrap is on, wrapping at `preferred_line_length` (100 by default; python/rust/js override it to match their own formatter's width) — don't assume lines are unwrapped
      - Relative line numbers are enabled to match helix-style relative motions
      - Buffer + terminal font is FiraCode Nerd Font Mono, so icon glyphs (starship.toml, nerd-font-based prompts) render correctly instead of as tofu boxes
    '';
  };
}
