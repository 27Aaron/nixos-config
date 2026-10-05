# Baseline Home Manager user configuration; the module list itself comes from
# the home profiles the host selects.
{
  host,
  osConfig,
  username,
  ...
}:
{
  home = {
    inherit username;
    homeDirectory = osConfig.users.users.${username}.home;
    stateVersion = host.homeStateVersion;
    language.collate = "C.UTF-8";
  };

  programs.home-manager.enable = true;

  # The second switch is what skips building the option manual; man.enable
  # alone does not.
  programs.man.enable = false;
  manual.manpages.enable = false;
}
