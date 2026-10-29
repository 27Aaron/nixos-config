{
  config,
  lib,
  ...
}:
let
  cfg = config.gui.zed;
in
{
  options.gui.zed.enable = lib.mkEnableOption "the Zed editor";

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

        # 全部信任的話,開啟惡意倉庫就會套用它的設定並啟動語言與 MCP 伺服器。
        # 須明確寫 false:合併不會移除 settings.json 裡既有的鍵。
        session.trust_all_worktrees = false;

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

    persist.directories = lib.mkIf config.persist.enable [
      ".config/zed"
      {
        directory = ".local/share/zed";
        mode = "0700";
      }
    ];
  };
}
