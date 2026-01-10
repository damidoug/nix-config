{ pkgs, ... }:
{
  home.packages = with pkgs; [
    podman
    podman-compose
  ];

  home.file = {
    ".config/containers/policy.json".source = ./pod-policy.json;
    ".config/containers/registries.conf".source = ./pod-registries.conf;
  };

  programs.zed-editor.extensions = [
    "dockerfile"
    "docker-compose"
  ];
}
