{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    python314
    ty
  ];

  programs.uv.enable = true;

  programs.ruff = {
    enable = true;
    settings = {
      line-length = 100;
      per-file-ignores = {
        "__init__.py" = [ "F401" ];
      };
      lint = {
        select = [
          "E4"
          "E7"
          "E9"
          "F"
        ];
        ignore = [ ];
      };
    };
  };

  programs.zed-editor.userSettings = {
    languages.Python = {
      code_actions_on_format = {
        "source.organizeImports.ruff" = true;
        "source.fixAll.ruff" = true;
      };
      language_servers = [
        "ty"
        "!basedpyright"
        "..."
      ];
    };
    lsp = {
      ty.binary = {
        path = "${lib.getExe pkgs.ty}";
        arguments = [ "server" ];
      };
      ruff.binary.path = "${lib.getExe pkgs.ruff}";
    };
  };
}
