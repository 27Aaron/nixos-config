{
  lib,
  username,
  ...
}:
{
  nix.settings.trusted-users = [ username ];

  programs.nh = {
    enable = true;
    flake = lib.mkDefault "/home/${username}/nixos-config";
  };

  preservation'.user.directories = [
    {
      directory = "nixos-config";
      mode = "0700";
    }
  ];
}
