{ pkgs, ... }:
{
  programs.bun = {
    enable = true;
    settings = {
      smol = true;
      telemetry = false;
    };
  };

  programs.zed-editor.extensions = [
    "vue"
    "svelte"
  ];

  home.packages = [ pkgs.nodejs ];
}
