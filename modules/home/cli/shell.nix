{
  programs = {
    # Shell 初始化與補全。
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting

        if command -q uv
          uv generate-shell-completion fish | source
        end

        if command -q uvx
          uvx --generate-shell-completion fish | source
        end
      '';
    };

    # Zsh 行為與補全。
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      initContent = ''
        if command -v uv &>/dev/null; then
          eval "$(uv generate-shell-completion zsh)"
        fi

        if command -v uvx &>/dev/null; then
          eval "$(uvx --generate-shell-completion zsh)"
        fi
      '';
      syntaxHighlighting.enable = true;
    };

    # 提示符樣式。
    starship = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        character = {
          success_symbol = "[›](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };

    # 目錄列表與導航。
    eza = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    # 命令歷史。
    atuin = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        sync_frequency = 0;
        inline_height = 30;
        history_filter = [
          ''^\s+''
          ''^ls($|(\s+((-([a-zA-Z0-9]|-)+)|"(\.|[^/])[^"]*"|'(\.|[^/])*'|(\.|[^/\s-])[^\s]*))*\s*$)''
          ''^cd($|\s+('[^/][^']*'|"[^/][^"]*"|[^/\s'"][^\s]*))$''
          "/nix/store/.*"
          ''--cookie[=\s]+.+''
        ];
      };
    };
  };

  # 上述 shell 與歷史工具的執行時狀態(fish 的狀態目錄由
  # modules/core/fish.nix 持久化)。
  persist' = {
    directories = [
      ".local/share/zoxide"
      {
        directory = ".atuin";
        mode = "0700";
      }
      ".local/share/atuin"

      # AI agents 的登入態與配置。
      {
        directory = ".claude";
        mode = "0700";
      }
      {
        directory = ".codex";
        mode = "0700";
      }
    ];

    files = [
      ".zsh_history"
      {
        file = ".claude.json";
        mode = "0600";
      }
    ];
  };

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
    cx = "codex --dangerously-bypass-approvals-and-sandbox";
    ll = "eza -lah";
    gs = "git status";
  };
}
