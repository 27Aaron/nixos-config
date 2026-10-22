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

  # 恢復後的兩個補救動作。這裡刻意不用 powerManagement.resumeCommands:
  # 在這個 nixpkgs 版本它不會產生任何 systemd 單元,寫了也不會執行
  # (2026-10-22 的恢復完全沒有留下它的輸出,證實沒跑過)。
  # 改用 After=sleep.target 的一次性服務,單元確實會被 sleep.target 拉起來。

  # 一、觸控板。走 I2C(AMDI0010 控制器上的 UNIW0001:00)。
  # 從休眠恢復時 i2c-hid 不會重新列舉,觸控板因此整個消失,
  # 2026-10-22 早上只能切 tty 重開機。USB 裝置有重新列舉的紀錄,
  # 只有 I2C 這條路徑漏了,所以恢復後手動重綁 i2c_hid_acpi 逼它重新探測。
  systemd.services.touchpad-resume-rebind = {
    description = "Re-bind the I2C HID touchpad after resuming";
    after = [ "sleep.target" ];
    wants = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      # 綁定失敗不該讓整個 sleep.target 變成失敗狀態。
      SuccessExitStatus = "0 1";
    };
    script = ''
      # 只有真的接在 i2c_hid_acpi 上才需要重綁;裝置不存在就安靜跳過。
      for dev in /sys/bus/i2c/devices/i2c-UNIW*; do
        [ -e "$dev" ] || continue
        drv="$(basename "$(readlink -f "$dev/driver" 2>/dev/null)")"
        [ "$drv" = "i2c_hid_acpi" ] || continue
        name="$(basename "$dev")"
        echo "re-binding $name"
        echo "$name" > /sys/bus/i2c/drivers/i2c_hid_acpi/unbind || true
        # 讓裝置有時間完成 teardown,太快重綁會拿到 EBUSY。
        sleep 0.5
        echo "$name" > /sys/bus/i2c/drivers/i2c_hid_acpi/bind || true
      done
    '';
  };

  # 二、蓋子狀態。logind 在休眠期間收不到 input 事件,若它最後一次認知是
  # 「關閉」,喚醒後就沒有機會自己修正,於是每次醒來都判定蓋子仍關著,
  # 再掛起一次,形成「解鎖後立刻被鎖回去」的迴圈。
  # 2026-10-22 09:51 與 09:51:55 兩次掛起前都沒有任何 Lid 事件,
  # 正是這個快取造成的。
  #
  # 恢復後比對 ACPI 的真實狀態與 logind 的認知,不一致就重新綁定 ACPI
  # button 裝置,逼驅動重新回報目前狀態。只在真的不一致時才動手,
  # 平常恢復不會被碰。
  systemd.services.lid-state-resync = {
    description = "Re-sync the cached lid state after resuming";
    after = [ "sleep.target" ];
    wants = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      SuccessExitStatus = "0 1";
    };
    script = ''
      lid_acpi=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}')
      lid_logind=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager LidClosed 2>/dev/null | awk '{print $2}')

      echo "lid after resume: acpi=''${lid_acpi:-unknown} logind_closed=''${lid_logind:-unknown}"

      if { [ "$lid_acpi" = "open" ] && [ "$lid_logind" = "true" ]; } ||
         { [ "$lid_acpi" = "closed" ] && [ "$lid_logind" = "false" ]; }; then
        echo "lid state mismatch, re-probing the ACPI button device"
        for dev in /sys/bus/acpi/devices/PNP0C0D:*; do
          [ -e "$dev" ] || continue
          name="$(basename "$dev")"
          driver="$(readlink -f "$dev/driver" 2>/dev/null)"
          [ -n "$driver" ] || continue
          echo "$name" > "$driver/unbind" 2>/dev/null || true
          sleep 0.3
          echo "$name" > "$driver/bind" 2>/dev/null || true
        done
      fi
    '';
  };

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
