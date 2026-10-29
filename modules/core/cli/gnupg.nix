{ config, lib, ... }:
{
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    {
      directory = ".gnupg";
      mode = "0700";
    }
  ];
}
