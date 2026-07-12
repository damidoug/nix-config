{ pkgs, ... }:
{
  programs = {
    brave = {
      enable = true;
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      commandLineArgs = [
        "--lang=en-US"
        "--accept-lang=en-US,en,pt-BR,pt"
      ];
      # extensions with no other owning module stay here (dark reader);
      # extensions tied to a specific app live in that app's own module and
      # merge into this same list (vencord web -> apps/vesktop, bitwarden ->
      # apps/bitwarden)
      extensions = [
        "kbbdabhdfibnancpjfhlkhafgdilcnji" # dark reader
      ];
    };

    aerospace.settings.mode.main.binding.alt-b = "exec-and-forget open -na 'Brave Browser'";

    claude-code.rules.brave = ''
      - Default/primary browser: Brave (NOT Safari/Chrome) — launch via alt-b in aerospace
      - Locale forced to en-US (`--lang=en-US --accept-lang=en-US,en,pt-BR,pt`) regardless of system locale
      - Extensions installed declaratively across modules (dark reader here, vencord web in apps/vesktop, bitwarden in apps/bitwarden) — don't suggest installing them manually
    '';
  };
}
