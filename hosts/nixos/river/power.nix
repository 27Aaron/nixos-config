{ pkgs, ... }:
{
  # 從加密的 swapfile 恢復。Btrfs 上要用物理偏移,重建或 balance 後重測:
  # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  boot = {
    resumeDevice = "/dev/mapper/crypted";
    kernelParams = [ "resume_offset=533760" ];
    # 預設只把記憶體回收到 RAM 的 2/5;之後凍結裝置時(多半是 amdgpu 把 VRAM
    # 搬回系統記憶體)還會再多用 2-3 GiB,超過快照能用的一半 RAM 就以 ENOMEM
    # 失敗。設為 0 讓核心盡量回收到磁碟 swap,代價是恢復後程式要從 swap 讀回。
    kernel.sysfs.power.image_size = 0;
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

  # 休眠恢復後的蓋子狀態(詳見 #177)。HibernateMode=shutdown 會完全斷電,
  # 開蓋不產生事件;_LID 讀取的 ACPI 變數又隨記憶體映像還原為「關」,
  # logind 因而反覆掛起。恢復必經電源鍵,蓋子必然開啟,故僅在此時以
  # lid_init_state=open 重綁 acpi-button。驅動於輸入裝置首次開啟時才回報
  # 初始狀態,open 須保留至下次睡眠前再還原;醒著時的開合仍由韌體事件回報。
  # 移除條件見 WORKAROUNDS.md 的 WA-002。
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

  # 觸控板(I2C,UNIW0001:00)休眠恢復後不會重新列舉,需重綁 i2c_hid_acpi。
  # resumeCommands 於恢復後執行,PATH 僅含 coreutils、grep、sed 與 systemd。
  # 移除條件見 WORKAROUNDS.md 的 WA-003。
  powerManagement.resumeCommands = ''
    for dev in /sys/bus/i2c/devices/i2c-UNIW*; do
      [ -e "$dev/driver" ] || continue
      [ "$(basename "$(readlink -f "$dev/driver")")" = "i2c_hid_acpi" ] || continue
      name="$(basename "$dev")"
      echo "touchpad: re-binding $name"
      echo "$name" > /sys/bus/i2c/drivers/i2c_hid_acpi/unbind || true
      # 立即重綁會回傳 EBUSY。
      sleep 0.5
      echo "$name" > /sys/bus/i2c/drivers/i2c_hid_acpi/bind || true
    done
  '';

  # 電源管理。
  desktop'.power-profiles-daemon.enable = true;
  desktop'.upower.enable = true;
}
