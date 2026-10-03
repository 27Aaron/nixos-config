{ lib, ... }:
{
  # Avoid concurrent local builds exhausting the VM's 1 GB memory limit.
  nix.settings.max-jobs = 1;

  # Keep the journal bounded on the small VM.
  services.journald.settings.Journal = lib.mkForce {
    SystemMaxUse = "128M";
  };

  services' = {
    fail2ban.enable = true;
    openssh.enable = true;
    vnstat.enable = true;
    zram.enable = true;
  };

  system.stateVersion = "26.05";
}
