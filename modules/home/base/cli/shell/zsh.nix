{ config, ... }:
{
  # fish 為主力,zsh 只作備援,不需列入 /etc/shells。
  programs.zsh = {
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
    syntaxHighlighting.enable = true;
  };

  persist'.directories = [
    {
      directory = ".cache/zsh";
      mode = "0700";
    }
    {
      directory = ".local/state/zsh";
      mode = "0700";
    }
  ];
}
