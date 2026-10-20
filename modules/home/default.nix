# Home Manager 使用者的接線與基準配置。
# 皆為常用所需,因此全部預設載入,不做逐模組選擇。
# 各工具模組經由 persist' 回報它們的狀態,由 persistence 模組拼接進 preservation。
{
  lib,
  vars,
  ...
}:
let
  # 狀態項目為相對於家目錄的路徑,或 preservation 接受的屬性集。
  entryType =
    kind:
    lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;

      options.${kind} = lib.mkOption {
        type = lib.types.str;
        description = "Home-relative path of the ${kind} to preserve.";
      };
    };
in
{
  # Home Manager 寫入 dconf 需要系統側的 dconf 支援。
  programs.dconf.enable = true;

  home-manager.users.${vars.username}.imports = [
    # 使用者基準:persist' 選項與家目錄、stateVersion 等基礎值。
    # osConfig 與 vars 由 Home Manager 提供給使用者模組。
    (
      { lib, osConfig, ... }:
      {
        options.persist' = {
          directories = lib.mkOption {
            type = lib.types.listOf (lib.types.either lib.types.str (entryType "directory"));
            default = [ ];
            description = ''
              Directories to preserve inside the user's home directory.
            '';
          };

          files = lib.mkOption {
            type = lib.types.listOf (lib.types.either lib.types.str (entryType "file"));
            default = [ ];
            description = ''
              Files to preserve inside the user's home directory.
            '';
          };
        };

        config = {
          home = {
            username = vars.username;
            homeDirectory = osConfig.users.users.${vars.username}.home;

            stateVersion = "26.11";
            language.collate = "C.UTF-8";
          };

          programs.home-manager.enable = true;

          # 要跳過 option manual 的建置,需要關掉第二個開關;
          # 單獨的 man.enable 不夠。
          programs.man.enable = false;
          manual.manpages.enable = false;
        };
      }
    )

    ./cli/development.nix
    ./cli/git.nix
    ./cli/shell.nix
    ./cli/tools.nix

    ./llm

    ./desktop/apps.nix
    ./desktop/chrome.nix
    ./desktop/cursor.nix
    ./desktop/firefox.nix
    ./desktop/kitty.nix
    ./desktop/magpie.nix
    ./desktop/mime-apps.nix
    ./desktop/theme.nix
    ./desktop/user-dirs.nix
    ./desktop/vscode.nix
    ./desktop/zed.nix
  ];
}
