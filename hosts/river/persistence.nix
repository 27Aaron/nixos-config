{
  vars,
  ...
}:

let
  user = vars.username;
in
{
  # preservation 需要在 initrd 階段掛載持久分割區,才能讀到 machine-id。
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
          # 動態使用者的 systemd 狀態(StateDirectory 服務)。
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
          # 需要在極早期寫入或讀取。
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

  # systemd-machine-id-commit.service 對 bind mount 的持久 machine-id 會
  # 執行失敗,在此配置中無關緊要,故予以抑制。
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
