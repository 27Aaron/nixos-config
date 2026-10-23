{ config, lib, ... }:
{
  programs.atuin = {
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

  # 指令歷史與同步金鑰。
  persist'.directories = lib.mkIf config.persist'.enable [
    {
      directory = ".atuin";
      mode = "0700";
    }
    {
      directory = ".local/share/atuin";
      mode = "0700";
    }
  ];
}
