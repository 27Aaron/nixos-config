{
  programs.zed-editor = {
    enable = true;

    # 名稱取自 zed-industries/extensions 的條目。
    extensions = [
      "catppuccin"
      "catppuccin-icons"
      "git-firefly"
      "nix"
      "toml"
    ];

    # 啟動時與既有 settings.json 合併,同名項目以這裡為準。
    userSettings = {
      # 版本由 Nix 更新,不要讓編輯器自己下載新版本。
      auto_update = false;

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      base_keymap = "Zed";
      hour_format = "hour24";

      # 新打開的目錄直接信任,不再逐個確認。
      session.trust_all_worktrees = true;

      # 跟隨系統深淺色。
      theme = {
        mode = "system";
        dark = "Catppuccin Mocha";
        light = "Catppuccin Latte";
      };
      icon_theme = {
        mode = "system";
        dark = "Catppuccin Mocha";
        light = "Catppuccin Latte";
      };

      # 等寬字型與 kitty 相同,游標同樣不閃。
      buffer_font_family = "Maple Mono NF";
      buffer_font_size = 14;
      cursor_blink = false;

      # 底部狀態列按鈕的停靠位置。Zed 1.24 預設是 Agentic 佈局:
      # 專案、Git 在右,Agent 在左。這裡改成專案與 Git 在左,Agent 在右。
      project_panel.dock = "left";
      git_panel.dock = "left";
      agent = {
        dock = "right";
        threads_sidebar.position = "right";
      };

      terminal = {
        dock = "bottom";
        font_family = "Maple Mono NF";
        font_size = 14;
        blinking = "off";
      };

      # 用 fish 的 direnv hook,讓 .envrc 進入編輯器與內建終端。
      load_direnv = "shell_hook";

      # 語言伺服器優先用 PATH 上的(mise、uv、direnv 或系統包)。
      # 找不到才會下載;下載的原生二進位在 NixOS 上通常跑不起來。
      lsp = {
        nixd.binary.path_lookup = true;
        basedpyright.binary.path_lookup = true;
        ruff.binary.path_lookup = true;
        gopls.binary.path_lookup = true;
        rust-analyzer.binary.path_lookup = true;
        vtsls.binary.path_lookup = true;
      };

      languages.Nix = {
        language_servers = [
          "nixd"
          "!nil"
        ];
        formatter.external = {
          command = "nixfmt";
          # 裸呼叫 nixfmt 讀標準輸入已棄用,要顯式傳 '-'。
          arguments = [ "-" ];
        };
        format_on_save = "on";
        tab_size = 2;
      };
    };
  };

  # 擴充功能、工作區資料庫與登入態在 .local/share/zed。
  # settings.json 由上面合併寫入 .config/zed,其餘檔案(快捷鍵、片段)由程式自己寫。
  persist'.directories = [
    ".config/zed"
    ".local/share/zed"
  ];
}
