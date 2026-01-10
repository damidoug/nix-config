{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs = {
    # A Cross-platform, GPU-accelerated terminal emulator
    alacritty.enable = true;

    # A 'cat' clone with syntax highlighting and Git integration.
    bat.enable = true;

    # A modern replacement for 'ls' with more features and better defaults.
    eza = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = pkgs.stdenv.isDarwin;
      git = true;
      icons = "auto";
    };

    # A friendly and interactive cheatsheet tool as an alternative
    fish.enable = true;

    # A simple, fast, and user-friendly alternative to 'find'.
    fd.enable = true;

    # A command-line fuzzy finder for quickly searching and navigating.
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = pkgs.stdenv.isDarwin;
      tmux.enableShellIntegration = true;
    };

    # A post-modern modal text editor.
    helix = {
      enable = true;
      settings = {
        theme = "autumn_night_transparent";
        editor.cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt;
        }
      ];
      themes = {
        autumn_night_transparent = {
          "inherits" = "autumn_night";
          "ui.background" = { };
        };
      };
    };

    # A recursive line-by-line search tool that's faster than 'grep'.
    ripgrep.enable = true;

    # A cross-shell prompt with Git and other integrations.
    starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = pkgs.stdenv.isDarwin;
      settings = lib.importTOML ./starship.toml;
    };

    # A youtube-dl fork with additional features.
    yt-dlp.enable = true;

    # A smarter 'cd' command that learns your habits for faster navigation.
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = pkgs.stdenv.isDarwin;
    };
  };

  home = {
    packages = with pkgs; [
      # A simple and secure secret management tool.
      inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
      # A modern and user-friendly replacement for 'curl'.
      curlie
      # A collaborative cheatsheet for console commands, an alternative to 'man'.
      tlrc
      # A more interactive and powerful alternative to 'jq' for JSON processing.
      jql
      # A handy command runner, an alternative to 'make'.
      just
      # A command-line tool to display information about the system.
      fastfetch
      # A feature-rich BitTorrent client.
      transmission_4
      # A set of patched fonts with a high number of glyphs (icons).
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      # A fast and minimal Git client.
      gitMinimal
      # A complete, cross-platform solution to record, convert, and stream audio and video.
      ffmpeg-full
    ];

    shellAliases = {
      cat = "bat";
      cd = "z";
      curl = "curlie";
      find = "fd";
      grep = "rg";
      jq = "jql";
      ls = "eza";
      man = "tldr";
    };

    sessionVariables = {
      TERMINAL = "alacritty";
      EDITOR = "hx";
    };
  };
}
