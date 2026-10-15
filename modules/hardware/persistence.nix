{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.hardware'.persistence;
  user = vars.username;

  # Home Manager 工具經由 persist' 回報它們保留的狀態。
  # 沒有載入任何 Home Manager 模組的主機,此橋接為空。
  persist =
    config.hm'.persist' or {
      directories = [ ];
      files = [ ];
    };
in
{
  # preservation 模組本體由 hosts/default.nix 統一引入,
  # 這裡只定義 preservation' 的選項別名。
  imports = [
    (lib.mkAliasOptionModule [ "preservation'" "os" ] [ "preservation" "preserveAt" "/persistent" ])
    (lib.mkAliasOptionModule
      [ "preservation'" "user" ]
      [ "preservation" "preserveAt" "/persistent" "users" user ]
    )
  ];

  options.hardware'.persistence = {
    enable = lib.mkEnableOption "Preservation for an ephemeral NixOS root";
  };

  config = lib.mkIf cfg.enable {
    # preservation 的 initrd 掛載(tmpfiles 規則)需要 systemd initrd。
    boot.initrd.systemd.enable = true;

    # preservation 需要在 initrd 階段掛載持久分割區,才能讀到 machine-id。
    fileSystems."/persistent".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persistent".commonMountOptions = [
        "x-gdu.hide"
        "x-gvfs-hide"
      ];
    };

    # 基礎使用者狀態;Home Manager 工具經由 persist'
    # 回報的狀態會附加在後。
    preservation'.user.directories = [
      # 把快取移出 tmpfs 根目錄,避免佔用過多記憶體。
      {
        directory = ".cache";
        mode = "0700";
      }

      # Nix 與 Home Manager
      ".local/share/nix"
      ".local/state/home-manager"
      ".local/state/nix/profiles"

      # 沒有專屬模組管理的憑證放在這裡。
      {
        directory = ".gnupg";
        mode = "0700";
      }
    ]
    ++ persist.directories;

    preservation'.user.files = persist.files;

    # 基礎系統所需的通用 NixOS 狀態。
    preservation'.os = {
      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
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
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };

    # systemd-machine-id-commit.service 會執行失敗,
    # 但對這種持久化 machine-id 的配置而言無關緊要,因此予以抑制。
    # (bind 掛載配方;commit 式改寫僅適用於 symlink 配方。)
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };
}
