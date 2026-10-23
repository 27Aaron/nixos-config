{
  programs'.homebrew.enable = true;

  hm' = {
    cli = {
      development.enable = true;
      toolchain.enable = true;
    };

    tui.claude-code.enable = true;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
