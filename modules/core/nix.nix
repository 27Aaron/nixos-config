{
  lib,
  vars,
  ...
}:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ vars.username ];
    };
  };

  programs.nh = {
    enable = true;
    flake = lib.mkDefault "/home/aaron/nix-config";
  };

  # nh 讀取的配置倉庫目錄。
  preservation'.user.directories = [
    {
      directory = "nix-config";
      mode = "0700";
    }
  ];
}
