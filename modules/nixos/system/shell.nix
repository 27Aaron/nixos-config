{
  lib,
  pkgs,
  username,
  ...
}:
{
  # fish is the interactive shell and Home Manager configures it; all this
  # module does is make it a valid login shell and the user's default, matching
  # the Darwin host.
  programs.fish.enable = lib.mkDefault true;

  users.users.${username}.shell = pkgs.fish;
}
