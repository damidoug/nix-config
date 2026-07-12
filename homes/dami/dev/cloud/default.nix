{ pkgs, ... }:
{
  home.packages = with pkgs; [
    flyctl
    cloudflared
  ];

  programs.claude-code.rules = {
    cloudflared = ''
      - Cloudflare tunnel CLI: `cloudflared`
      - Tunnels are managed declaratively via NixOS services on homelab — don't run `cloudflared tunnel create/route` imperatively on managed hosts, edit the NixOS module instead
      - Local/ad-hoc tunnels (`cloudflared tunnel --url ...`) are fine for one-off testing, but aren't how production tunnels are set up here
    '';

    flyctl = ''
      - Fly.io CLI: `flyctl` (aliased `fly`) — `fly deploy`, `fly status`, `fly logs`, `fly ssh console`
      - Per-app config lives in that project's own `fly.toml`, not in this Nix flake — don't look here for Fly app config
      - Secrets go through `fly secrets set`, never committed to the repo
    '';
  };
}
