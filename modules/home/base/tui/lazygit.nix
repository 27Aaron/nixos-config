{ config, lib, ... }:
{
  programs.lazygit.enable = true;

  persist.directories = lib.mkIf config.persist.enable [ ".local/state/lazygit" ];
}
