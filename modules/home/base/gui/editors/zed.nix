{
  config,
  lib,
  ...
}:
let
  cfg = config.gui'.zed;
in
{
  options.gui'.zed.enable = lib.mkEnableOption "the Zed editor";

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;

      # 名稱取自 zed-industries/extensions。
      extensions = [
        "catppuccin"
        "catppuccin-icons"
        "git-firefly"
        "nix"
        "toml"
      ];

      # 與既有 settings.json 合併,同名項目以此為準。
      userSettings = {
        # 由 Nix 負責更新。
        auto_update = false;

        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        base_keymap = "Zed";
        hour_format = "hour24";

        # 新目錄直接信任,不再逐個確認。
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

        ui_font_family = "LXGW WenKai TC";
        agent_ui_font_family = "LXGW WenKai TC";

        # 與 kitty 相同的等寬字型。
        buffer_font_family = "Maple Mono NF";
        buffer_font_size = 14;
        cursor_blink = false;

        # 專案與 Git 面板放左側,Agent 放右側(Zed 1.24 預設相反)。
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

        # 透過 shell 的 direnv hook 載入 .envrc。
        load_direnv = "shell_hook";

        # 語言伺服器優先使用 PATH 上的版本;Zed 自行下載的二進位在 NixOS 上
        # 通常無法執行。
        lsp = {
          nixd.binary.path_lookup = true;
          basedpyright.binary.path_lookup = true;
          ruff.binary.path_lookup = true;
          gopls.binary.path_lookup = true;
          rust-analyzer.binary.path_lookup = true;
          vtsls.binary.path_lookup = true;
          package-version-server.binary.path_lookup = true;
        };

        languages.Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
          formatter.external = {
            command = "nixfmt";
            # 從標準輸入讀取需明確傳入 '-'。
            arguments = [ "-" ];
          };
          format_on_save = "on";
          tab_size = 2;
        };
      };
    };

    # .config/zed 存放合併後的 settings.json 與快捷鍵、片段;擴充功能、
    # 工作區資料庫與登入狀態在 .local/share/zed。
    persist'.directories = [
      ".config/zed"
      ".local/share/zed"
    ];
  };
}
