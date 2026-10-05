{
  config,
  lib,
  preservation,
  username,
  ...
}:
let
  cfg = config.hardware'.persistence;

  # Home Manager tools report the state they keep through `persist'`. A host
  # that runs no Home Manager user modules leaves the bridge undefined.
  persist =
    config.hm'.persist' or {
      directories = [ ];
      files = [ ];
    };
in
{
  imports = [
    preservation.nixosModules.default
    (lib.mkAliasOptionModule [ "preservation'" "os" ] [ "preservation" "preserveAt" "/persistent" ])
    (lib.mkAliasOptionModule
      [ "preservation'" "user" ]
      [ "preservation" "preserveAt" "/persistent" "users" username ]
    )
  ];

  options.hardware'.persistence = {
    enable = lib.mkEnableOption "the preservation-backed ephemeral root";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd.enable = true;
    boot.tmp.cleanOnBoot = true;
    fileSystems."/persistent".neededForBoot = true;

    preservation.enable = true;
    preservation'.os = {
      commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/lib/lastlog"
        "/var/lib/systemd"
        {
          directory = "/var/lib/private";
          mode = "0700";
        }
        "/var/log"
        {
          directory = "/var/tmp";
          mode = "1777";
        }
      ];
    };

    # Baseline state every user needs. Feature-owned state is declared next to
    # the feature itself and reaches this option through the `persist'` bridge.
    preservation'.user.directories = [
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
    ]
    ++ persist.directories;

    preservation'.user.files = persist.files;

    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        ""
        "/persistent/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        ""
        "systemd-machine-id-setup --commit --root /persistent"
      ];
    };
  };
}
