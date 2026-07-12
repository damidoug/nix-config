{ pkgs, ... }:
{
  home.packages = with pkgs; [ mitmproxy ];

  programs.claude-code.rules.proxy = ''
    - HTTP proxy/inspector: mitmproxy — `mitmproxy` (TUI), `mitmweb` (browser UI), `mitmdump` (headless/scriptable)
    - Run `webproxy` to start mitmweb and open Brave pre-configured to use it — that's the normal entry point, not a bare `mitmproxy`/`mitmweb` invocation
    - Proxy listens on port 8080; the web UI is at http://127.0.0.1:8081
    - HTTPS interception requires trusting mitmproxy's CA once per client (visit mitm.it while proxied) — if TLS errors show up, that's the likely cause, not a broken proxy
  '';
}
