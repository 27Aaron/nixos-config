{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.openssh;
  persistenceEnabled = config.hardware'.persistence.enable;
in
{
  options.services'.openssh = {
    enable = lib.mkEnableOption "OpenSSH daemon";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      hostKeys = lib.mkDefault [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        PermitRootLogin = lib.mkDefault "prohibit-password";
        PasswordAuthentication = lib.mkDefault false;
        KbdInteractiveAuthentication = lib.mkDefault false;
        X11Forwarding = lib.mkDefault false;
      };
    };

    preservation'.os.directories = lib.mkIf persistenceEnabled [ "/etc/ssh" ];
    preservation'.user = lib.mkIf persistenceEnabled {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };
}
