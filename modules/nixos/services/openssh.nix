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
      enable = lib.mkDefault true;
      ports = lib.mkDefault [ 233 ];
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

    environment.enableAllTerminfo = lib.mkDefault true;

    preservation' = lib.mkIf persistenceEnabled {
      os.directories = [
        {
          directory = "/etc/ssh";
          inInitrd = true;
        }
      ];
      user.directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };
}
