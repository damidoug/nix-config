{ ... }:
{
  programs = {
    fd.enable = true;

    claude-code.rules.finder = ''
      - File finder: `fd` (NOT find — fd is faster and has better defaults)
      - Example: `fd pattern`, `fd -e nix`, `fd -t f pattern`
    '';
  };
}
