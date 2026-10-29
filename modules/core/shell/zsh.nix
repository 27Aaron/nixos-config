{ config, lib, ... }:
{
  # fish 為主力,zsh 只作備援,不需列入 /etc/shells。
  hm'.programs.zsh = {
    enable = true;
    enableCompletion = true;

    # compinit 與歷史存檔都以 rename() 寫入,單檔 bind 掛載會導致 EBUSY,
    # 因此改放在整目錄持久化的 ~/.cache/zsh 與 ~/.local/state/zsh。
    completionInit = ''
      mkdir -p "$HOME/.cache/zsh"
      autoload -U compinit && compinit -d "$HOME/.cache/zsh/.zcompdump"
    '';

    history.path = "${config.hm'.xdg.stateHome}/zsh/history";

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
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
