{ config, lib, ... }:
{
  hm'.programs.zoxide = {
    enable = true;
  };

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".local/share/zoxide"
  ];
}
