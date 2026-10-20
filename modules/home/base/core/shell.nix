{
  # 兩個 shell 都是刻意啟用的,不是遺留:
  #   fish 是主力,系統側 modules/nixos/base/core/fish.nix 把它設為登錄 shell;
  #   zsh 是備援,少數情況下 fish 跑不起來(某些安裝腳本、只認 POSIX shell 的
  #   環境)時改用它,比 bash 好用。
  # programs.zsh.enable 會把 zsh 裝進 ~/.nix-profile,所以 `zsh` 隨時可用;
  # 它沒有進 /etc/shells,因為不需要設成登錄 shell。
  programs = {
    # 主力 shell。
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

    # 備援 shell 的行為與補全;提示符、目錄跳轉與歷史見下方。
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
  # modules/nixos/base/core/fish.nix 持久化)。
  persist' = {
    directories = [
      ".local/share/zoxide"
      {
        directory = ".atuin";
        mode = "0700";
      }
      ".local/share/atuin"
    ];

    files = [
      ".zsh_history"
    ];
  };

  home.shellAliases = {
    ll = "eza -lah";
    gs = "git status";
  };
}
