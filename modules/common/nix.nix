{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    alejandra
    deadnix
    nixd
  ];

  nix = {
    channel.enable = false;
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
    optimise.automatic = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      builders-use-substitutes = true;
    };
  };

  nixpkgs.config.allowUnfree = true;
}
