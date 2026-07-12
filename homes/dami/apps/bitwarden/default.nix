{ pkgs, lib, ... }:
{
  # nixpkgs' bitwarden-desktop needs a native module built from source and
  # fails on every channel available here on darwin (unstable's toolchain
  # crashes linking it; nixpkgs-stable's own stdenv-darwin fails earlier
  # still, LLVM 18's compiler-rt against the newer Apple SDK). Linux only
  # until a binary build replaces it.
  home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-desktop ];

  programs = {
    brave.extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
    ];

    aerospace.settings.mode.main.binding.alt-p = "exec-and-forget open -a 'Bitwarden'";

    claude-code.rules.bitwarden = ''
      - Password manager: Bitwarden desktop app — launch via alt-p in aerospace
      - Linux only for now: nixpkgs' bitwarden-desktop fails to build from source on darwin — not installed there until a binary build replaces it
      - Bitwarden browser extension is installed declaratively in Brave — don't suggest installing it manually
    '';
  };
}
