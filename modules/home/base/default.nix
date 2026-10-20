# 兩個平臺共用的 Home Manager 基準:persist' 選項、帳號設定,以及 core/tui/
# gui 三桶的檔案清單。平臺專屬的東西放 ../nixos 或 ../darwin。
{
  lib,
  osConfig,
  vars,
  ...
}:
let
  # 狀態項目可寫成家目錄相對路徑,或帶屬性的集合。
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
  imports = [
    # core:自己不畫介面。
    ./core/development.nix
    ./core/git.nix
    ./core/packages.nix
    ./core/shell.nix
    ./core/toolchain.nix

    # tui:接管終端。
    ./tui/agents/claude-code.nix
    ./tui/agents/dsh.nix
    ./tui/git/lazygit.nix
    ./tui/monitoring.nix

    # gui:開一個視窗。
    ./gui/agents/claude-desktop.nix
    ./gui/agents/dsh-desktop.nix
    ./gui/nagram.nix
    ./gui/seahorse.nix
    ./gui/browsers/chrome.nix
    ./gui/browsers/firefox.nix
    ./gui/pointer-cursor.nix
    ./gui/editors/vscode.nix
    ./gui/editors/zed.nix
    ./gui/mime-apps.nix
    ./gui/terminal/kitty.nix
    ./gui/theme.nix
    ./gui/user-dirs.nix
  ];

  # 各工具模組回報自己的狀態,由 persistence 模組拼接進 preservation。
  options.persist' = {
    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "directory"));
      default = [ ];
      description = "Directories to preserve in the home directory.";
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "file"));
      default = [ ];
      description = "Files to preserve in the home directory.";
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

    # 跳過 option manual 的建置要關兩個開關,單獨的 man.enable 不夠。
    programs.man.enable = false;
    manual.manpages.enable = false;
  };
}
