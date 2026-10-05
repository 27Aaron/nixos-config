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

  # Runtime state of the toolset above: the direnv .envrc allow-list, the
  # mise-managed toolchains, and uv-managed interpreters and tools.
  persist'.directories = [
    ".local/share/direnv"
    ".local/share/mise"
    ".local/share/uv"
  ];
}
