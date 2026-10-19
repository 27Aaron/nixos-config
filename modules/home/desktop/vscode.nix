{
  pkgs,
  ...
}:
let
  # 策展集合沒有的擴充功能,從 Marketplace 鎖定版本與雜湊。
  kdl = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "kdl";
      publisher = "kdl-org";
      version = "2.1.3";
      sha256 = "sha256-Jssmb5owrgNWlmLFSKCgqMJKp3sPpOrlEUBwzZSSpbM=";
    };
  };
  nixExtensionPack = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "nix-extension-pack";
      publisher = "pinage404";
      version = "3.0.0";
      sha256 = "sha256-cWXd6AlyxBroZF+cXZzzWZbYPDuOqwCZIK67cEP5sNk=";
    };
  };
in
{
  programs.vscode = {
    enable = true;

    profiles.default = {
      # 安裝清單即聲明:每次切換同步成這份清單,策展集合的版本跟著 nixpkgs 走;
      # 未列出的擴充功能仍可在編輯器裡自行安裝。
      extensions = with pkgs.vscode-extensions; [
        # Nix 語言支援:語法、格式化與相關擴充功能合集。
        jnoortheen.nix-ide
        nixExtensionPack

        # 開發環境:擴充功能宿主與語言伺服器跟著 .envrc 走。
        arrterian.nix-env-selector
        mkhl.direnv

        # 佈景主題與圖示。
        catppuccin.catppuccin-vsc
        pkief.material-icon-theme

        # KDL 設定檔語法,編輯 niri 配置用。
        kdl
      ];
    };
  };

  # 設定與登入態由程式自行寫入,只保留跨重啟。
  # userSettings 未宣告,settings.json 不會被 Home Manager 碰。
  persist'.directories = [
    # 使用者設定、工作區狀態與登入態。
    ".config/Code"

    # 擴充功能(programs.vscode 也安裝在這裡)。
    ".vscode"

    # 新版 Code 的共享狀態:信任清單與最近開啟清單都在這裡。
    # 沒有它,每次重啟後都會忘記已信任的工作區,重新跳出信任確認。
    ".vscode-shared"
  ];
}
