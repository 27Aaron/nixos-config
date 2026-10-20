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
    kernelParams = [
      "resume_offset=533760"

      # 韌體在休眠恢復時會誤報蓋子為關閉(kernel 記錄為
      # "Unexpected lid state reported by firmware")。logind 一旦記住這個
      # 錯誤狀態就不再收到 open 事件,之後每次喚醒都判定蓋子仍關著而再次
      # 掛起,形成「解鎖後立刻被鎖回去」的迴圈。
      # 強制 button 驅動回報初始狀態為 open,避開恢復時的誤判。
      "button.lid_init_state=open"
    ];
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

  # 恢復後比對蓋子狀態。休眠期間 logind 收不到任何 input 事件,若它最後一次
  # 認知是「關閉」,醒來後就會一直以為蓋子還關著,並在每次喚醒後再次掛起,
  # 形成「解鎖後立刻被鎖回去」的迴圈。這裡只記錄兩邊的認知是否一致,
  # 不介入狀態,以免引入新的風險。
  powerManagement.resumeCommands = ''
    lid_acpi=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}')
    lid_logind=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
      org.freedesktop.login1.Manager LidClosed 2>/dev/null | awk '{print $2}')

    echo "lid after resume: acpi=''${lid_acpi:-unknown} logind_closed=''${lid_logind:-unknown}"

    if { [ "$lid_acpi" = "open" ] && [ "$lid_logind" = "true" ]; } ||
       { [ "$lid_acpi" = "closed" ] && [ "$lid_logind" = "false" ]; }; then
      echo "lid state mismatch: ACPI reports $lid_acpi but logind believes the opposite"
    fi
  '';

  # 暫時開啟 logind 的 debug 日誌,用來確認喚醒後再次掛起的真正發起者
  # (蓋子事件、閒置逾時,或 D-Bus 呼叫)。確認原因後可移除。
  systemd.services.systemd-logind.serviceConfig.Environment = [ "SYSTEMD_LOG_LEVEL=debug" ];

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
