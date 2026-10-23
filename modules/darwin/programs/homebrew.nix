{
  config,
  lib,
  ...
}:
let
  cfg = config.programs'.homebrew;
in
{
  options.programs'.homebrew = {
    enable = lib.mkEnableOption "Homebrew package management";
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;

      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;

      # 啟用時不連網更新,版本只在手動 brew upgrade 時變動;
      # zap 會移除清單外的套件,讓清單成為唯一來源。
      onActivation = {
        upgrade = false;
        autoUpdate = false;
        cleanup = "zap";
      };

      taps = [ ];

      masApps = {
        "Bob" = 1630034110;
        "WPS" = 1443749478;
      };

      brews = [
        # 磁碟與清理
        "mole"

        # 程式碼統計
        "tokei"

        # 媒體
        "ffmpeg"
      ];

      casks = [
        # AI 開發
        "cc-switch"
        "codexbar"
        "zcode"

        # 瀏覽器
        # "brave-browser"
        "firefox"
        "google-chrome"

        # 通訊
        "feishu"
        "telegram"
        "wechat"

        # 開發
        "orbstack"

        # 編輯器
        "visual-studio-code"
        "zed"

        # 字型
        "font-lxgw-wenkai"
        "font-hack-nerd-font"
        "font-material-icons"
        "font-maple-mono-nf-cn"
        "font-jetbrains-mono-nerd-font"

        # 硬體
        "macs-fan-control"
        "monitorcontrol"

        # 輸入法與鍵盤
        "input-source-pro"
        "karabiner-elements"

        # 知識庫
        "obsidian"

        # 媒體
        "iina"
        "neteasemusic"
        "obs"
        "plex"

        # 選單列
        "jordanbaird-ice@beta"

        # 網路工具
        "surge"

        # 生產力
        "qspace-pro"
        "raycast"

        # 遠端存取
        "uuremote"

        # SSH 用戶端
        "termius"

        # 系統監控
        "stats"

        # 終端機
        "ghostty"
        "kitty"
      ];
    };
  };
}
