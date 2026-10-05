{ ... }:
{
  # Load project environments with direnv and nix-direnv.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Enable mise without managing its global tool versions here.
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # Install uv through Home Manager.
  programs.uv.enable = true;
}
