{ config, lib, ... }:
{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  persist'.directories = lib.mkIf config.persist'.enable [ ".local/share/zoxide" ];
}
