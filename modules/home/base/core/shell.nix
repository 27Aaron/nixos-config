{
  # 兩個 shell 都是刻意啟用的:fish 是主力,由 nixos/base/core/fish.nix 設為
  # 登錄 shell;zsh 是備援,fish 跑不起來的場合改用它,比 bash 好用。
  # zsh 沒進 /etc/shells,因為不需要設成登錄 shell。
  programs = {
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

    zsh = {
      enable = true;
      enableCompletion = true;

      # compinit 先寫 .zcompdump.<host>.<pid> 再 mv 成正式檔;直接綁定
      # .config/zsh/.zcompdump 會讓 mv 撞上 EBUSY,所以放到可整目錄持久化的
      # .cache/zsh,效果一樣。
      completionInit = ''
        mkdir -p "$HOME/.cache/zsh"
        autoload -U compinit && compinit -d "$HOME/.cache/zsh/.zcompdump"
      '';

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

    atuin = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        sync_frequency = 0;
        inline_height = 30;
        # 不記錄無意義的指令,免得搜尋被淹掉。
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

  # fish 的狀態目錄由 nixos/base/core/fish.nix 持久化。
  persist' = {
    directories = [
      ".local/share/zoxide"
      {
        directory = ".atuin";
        mode = "0700";
      }
      ".local/share/atuin"
      {
        directory = ".cache/zsh";
        mode = "0700";
      }
    ];

    files = [
      {
        file = ".zsh_history";
        mode = "0600";
      }
    ];
  };

  home.shellAliases = {
    ll = "eza -lah";
    gs = "git status";
  };
}
