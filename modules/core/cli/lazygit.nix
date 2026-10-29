{ config, lib, ... }:
{
  hm'.programs.lazygit.enable = true;

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".local/state/lazygit"
  ];
}
