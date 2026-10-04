{ config, lib, ... }:
let
  cfg = config.security'.firewall;
in
{
  options.security'.firewall = {
    enable = lib.mkEnableOption "firewall with nftables";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall.enable = true;
      nftables.enable = true;
    };
  };
}
