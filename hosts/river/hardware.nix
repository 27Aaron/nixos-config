# Hardware profile for the MECHREVO WUJIE14XA (Wujie 14X Blizzard) laptop.
#
#   DMI        MECHREVO WUJIE14XA, board WUJIE14-GX4HRXL, BIOS N.1.14MRO50
#   CPU        AMD Ryzen 7 8845HS (Phoenix / Hawk Point), 8C/16T
#   Memory     2 x 16 GB DDR5-5600, Crucial/Micron CT16G56C46S5.C8D
#   GPU        Radeon 780M (HawkPoint1)                  [1002:1900]
#   Wi-Fi      MediaTek MT7922 (RZ616), mt7921e          [14c3:7922]
#   Bluetooth  13d3:3585, the Bluetooth half of the MT7922
#   Ethernet   Motorcomm YT6801, needs Linux >= 7.0      [1f0a:6801]
#   Touchpad   UNIW0001:00 093A:0255, on I2C rather than PS/2
#   Audio      Radeon HD Audio + Ryzen HD Audio          [1002:1640], [1022:15e3]
#   USB4       single-cable USB-C display output works   [1022:1669]
#   Storage    Micron 2550 NVMe SSD, 1 TB
#   TPM        present (/dev/tpm0)
#   Sensors    k10temp, amdgpu, nvme, BAT0, spd5118 x2
#   Power      s2idle only
#   Webcam     IR camera                                 [04f2:b7dd]
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 磁碟與檔案系統佈局(ESP、LUKS、Btrfs、swapfile)。
  hardware'.disko = {
    enable = true;
    device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_24364AD5D8E0";
    espSize = "1G";
    swapSize = "32769M";
    luks.enable = true;
    luks.fido2.enable = true;
  };

  # 開機:載入器、核心與 initrd、休眠。
  hardware'.systemd-boot.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # 開機畫面不顯示 ACPI 這類錯誤,記錄仍在 journal 裡。
    consoleLogLevel = 3;

    initrd = {
      # preservation 的硬性需求;同時讓 LUKS 的 crypttab 選項生效。
      systemd.enable = true;

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    # 從加密的 swapfile 恢復。Btrfs 上要用物理偏移,重建或 balance 後重測:
    # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
    resumeDevice = "/dev/mapper/crypted";
    kernelParams = [ "resume_offset=533760" ];
  };

  # 韌體只有 s2idle,沒有 S3。合蓋先睡眠,一小時後再休眠。
  # 接電不開始倒數,就停在睡眠。外接螢幕時合蓋不睡眠,內建面板仍可使用。
  systemd.sleep.settings.Sleep = {
    AllowSuspendThenHibernate = "yes";
    HibernateMode = "shutdown";
    HibernateOnACPower = "no";
    HibernateDelaySec = "1h";
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
  };

  # 觸控板走 I2C(AMDI0010 控制器上的 UNIW0001:00),從休眠恢復時
  # i2c-hid 不會重新列舉,重綁 i2c_hid_acpi 逼它重新探測。
  # resumeCommands 是 sleep-actions.service 的 ExecStop,醒來後才執行;
  # 這個環境的 PATH 只有 coreutils、grep、sed 與 systemd,沒有 awk。
  powerManagement.resumeCommands = ''
    for dev in /sys/bus/i2c/devices/i2c-UNIW*; do
      [ -e "$dev/driver" ] || continue
      [ "$(basename "$(readlink -f "$dev/driver")")" = "i2c_hid_acpi" ] || continue
      name="$(basename "$dev")"
      echo "touchpad: re-binding $name"
      echo "$name" > /sys/bus/i2c/drivers/i2c_hid_acpi/unbind || true
      # 太快重綁會拿到 EBUSY。
      sleep 0.5
      echo "$name" > /sys/bus/i2c/drivers/i2c_hid_acpi/bind || true
    done
  '';

  # 蓋子狀態。休眠是 HibernateMode=shutdown,開蓋時機器完全斷電,
  # 開蓋事件沒人收到;_LID 讀的 ACPI 變數又跟著記憶體快照一起還原,
  # 恢復後持續回報「關」(2026-10-22 10:46 實測輪詢十秒皆為 closed)。
  # logind 於是依 HandleLidSwitch 一再掛起,形成解鎖後又被鎖回去的迴圈。
  #
  # 從休眠恢復必須按電源鍵,蓋子必然開著,所以只在這種情況下,
  # 把 lid_init_state 改成 open 再重綁 acpi-button。驅動要等輸入裝置
  # 第一次被打開(logind 在 systemd-sleep 結束後才打開)才回報初始狀態,
  # 所以 open 必須保留到下次睡眠前才改回 method;2026-10-22 11:00 的
  # 測試就是太早改回,logind 打開時又讀到 _LID 的「關」。醒著時的開合蓋
  # 走韌體事件,不受這個參數影響;一般睡眠的恢復仍照 method 問 _LID。
  environment.etc."systemd/system-sleep/lid-after-hibernate".source =
    pkgs.writeShellScript "lid-after-hibernate" ''
      params=/sys/module/button/parameters/lid_init_state
      driver=/sys/bus/platform/drivers/acpi-button
      if [ "$1" = pre ]; then
        echo method > "$params"
        exit 0
      fi
      [ "$1" = post ] && [ "$SYSTEMD_SLEEP_ACTION" = hibernate ] || exit 0
      echo "lid: resumed from hibernation, re-binding acpi-button as open"
      echo open > "$params"
      echo PNP0C0D:00 > "$driver/unbind" || true
      ${pkgs.coreutils}/bin/sleep 0.3
      echo PNP0C0D:00 > "$driver/bind" || true
    '';

  # 韌體與週邊驅動。
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware'.amdgpu.enable = true;
  hardware'.bluetooth.enable = true;
  hardware'.brightness.enable = true;

  # 狀態持久化。
  hardware'.persistence.enable = true;

  # 與本機硬體綁定的服務:電源管理、壓縮 swap、磁碟健康與 Btrfs 維護。
  services' = {
    # 電源
    power-profiles-daemon.enable = true;
    upower.enable = true;

    # 壓縮 swap
    zram = {
      enable = true;
      # 上限 16G(記憶體不足 16G 時則用滿記憶體)
      memoryPercent = 100;
      memoryMax = 16 * 1024 * 1024 * 1024;
    };

    # 磁碟健康與 Btrfs 維護
    smartd.enable = true;
    btrfs-scrub.enable = true;
    btrbk.enable = true;
  };
}
