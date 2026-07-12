{ pkgs, ... }:
{
  programs = {
    aerospace = {
      enable = pkgs.stdenv.isDarwin;
      launchd.enable = true;

      settings = {
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;

        accordion-padding = 30;

        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";

        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

        automatically-unhide-macos-hidden-apps = false;

        key-mapping.preset = "qwerty";

        gaps = {
          inner.horizontal = 0;
          inner.vertical = 0;
          outer.left = 0;
          outer.bottom = 0;
          outer.top = 0;
          outer.right = 0;
        };

        mode.main.binding = {
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";

          alt-left = "focus left";
          alt-down = "focus down";
          alt-up = "focus up";
          alt-right = "focus right";

          alt-shift-left = "move left";
          alt-shift-down = "move down";
          alt-shift-up = "move up";
          alt-shift-right = "move right";

          alt-minus = "resize smart -50";
          alt-equal = "resize smart +50";

          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";
          alt-5 = "workspace 5";
          alt-6 = "workspace 6";
          alt-7 = "workspace 7";
          alt-8 = "workspace 8";
          alt-9 = "workspace 9";

          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
          alt-shift-5 = "move-node-to-workspace 5";
          alt-shift-6 = "move-node-to-workspace 6";
          alt-shift-7 = "move-node-to-workspace 7";
          alt-shift-8 = "move-node-to-workspace 8";
          alt-shift-9 = "move-node-to-workspace 9";

          alt-tab = "workspace-back-and-forth";
          alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
          alt-shift-semicolon = "mode service";

          alt-f = "exec-and-forget open -a Finder";
        };

        mode.service.binding = {
          esc = [
            "reload-config"
            "mode main"
          ];
          r = [
            "flatten-workspace-tree"
            "mode main"
          ];
          f = [
            "layout floating tiling"
            "mode main"
          ];
          backspace = [
            "close-all-windows-but-current"
            "mode main"
          ];

          alt-shift-h = [
            "join-with left"
            "mode main"
          ];
          alt-shift-j = [
            "join-with down"
            "mode main"
          ];
          alt-shift-k = [
            "join-with up"
            "mode main"
          ];
          alt-shift-l = [
            "join-with right"
            "mode main"
          ];
        };
      };
    };

    claude-code.rules.aerospace = ''
      - Window manager: aerospace (macOS-only tiling WM, `programs.aerospace.enable = pkgs.stdenv.isDarwin`)
      - App-launch bindings are split across modules and merge into one config — alt-f (Finder) is set here since Finder has no module; alt-enter/alt-b/alt-c/alt-p live in ghostty/brave/zed/bitwarden's own rules
      - Workspace bindings: alt-1..9 switch, alt-shift-1..9 move window to workspace, alt-tab = back-and-forth
      - Focus/move: alt-arrows to focus, alt-shift-arrows to move
      - `alt-shift-semicolon` enters "service" mode (reload config, flatten tree, toggle floating, join-with) — esc exits back to main mode
    '';
  };
}
