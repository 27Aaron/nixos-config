# 跨平臺共用的 Home Manager 設定:persist' 選項、帳號設定與模組清單。
# 平臺專屬設定放在 ../nixos 或 ../darwin。
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
    # core:不繪製介面。
    ./core/development.nix
    ./core/git.nix
    ./core/packages.nix
    ./core/shell.nix
    ./core/toolchain.nix

    # tui:佔用終端機。
    ./tui/agents/claude-code.nix
    ./tui/agents/dsh.nix
    ./tui/git/lazygit.nix
    ./tui/monitoring.nix

    # gui:開啟視窗。
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

  # 各模組回報的狀態路徑,由 persistence 模組併入 preservation。
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

    # 兩者都關閉才能跳過 option manual 的建置。
    programs.man.enable = false;
    manual.manpages.enable = false;
  };
}
