{
  lib,
  username,
  ...
}:
{
  nix.settings.trusted-users = [ username ];

  programs.nh = {
    enable = true;
    flake = lib.mkDefault "/home/${username}/nix-config";
  };

  preservation'.user.directories = [
    {
      directory = "nix-config";
      mode = "0700";
    }
  ];
}
