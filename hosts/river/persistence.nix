{
  vars,
  ...
}:

let
  user = vars.username;
in
{
  # Preservation needs the persistent storage in the initrd for machine-id.
  fileSystems."/persistent".neededForBoot = true;

  preservation = {
    enable = true;

    preserveAt."/persistent" = {
      commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];

      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        "/var/lib/AccountsService"
        "/var/lib/lastlog"
        "/var/lib/systemd"
        {
          # Systemd-managed state of dynamic users (StateDirectory services).
          directory = "/var/lib/private";
          mode = "0700";
        }
        "/var/log"
        {
          directory = "/var/tmp";
          mode = "1777";
        }
      ];

      files = [
        {
          # Needs to be populated/read very early.
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      users.${user}.directories = [
        {
          directory = ".cache";
          mode = "0700";
        }
        ".local/share/nix"
        ".local/state/home-manager"
        ".local/state/nix/profiles"
        {
          directory = ".gnupg";
          mode = "0700";
        }
      ];
    };
  };

  # systemd-machine-id-commit.service would fail against the bind-mounted
  # persistent machine-id, which is not relevant in this setup.
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
