{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  persist'.directories = [ ".local/share/zoxide" ];
}
