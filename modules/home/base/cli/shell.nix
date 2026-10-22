{ config, ... }:
{
  # fish 為主力(登入 shell 由 nixos/base/core/fish.nix 設定);zsh 為備援,
  # 不需列入 /etc/shells。
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

      # compinit 與歷史存檔都以 rename() 寫入,單檔 bind 掛載會導致 EBUSY,
      # 因此改放在整目錄持久化的 ~/.cache/zsh 與 ~/.local/state/zsh。
      completionInit = ''
        mkdir -p "$HOME/.cache/zsh"
        autoload -U compinit && compinit -d "$HOME/.cache/zsh/.zcompdump"
      '';

      history.path = "${config.xdg.stateHome}/zsh/history";

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
        # 過濾瑣碎指令與含敏感參數的指令。
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
      {
        directory = ".local/state/zsh";
        mode = "0700";
      }
    ];
  };

  home.shellAliases = {
    ll = "eza -lah";
    gs = "git status";
  };
}
