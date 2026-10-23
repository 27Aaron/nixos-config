{
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  home.shellAliases.ll = "eza -lah";
}
