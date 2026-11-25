{ pkgs, ... }:
{
  # 恢復位置由 systemd 休眠時寫進 EFI 變數 HibernateLocation,不必寫死 Btrfs
  # swapfile 的 resume_offset;重新安裝後也不用重新量測。image_size 由
  # hardware'.disko 在有 swapfile 時設為 0。

  # 韌體只有 s2idle,沒有 S3,所以合蓋後一小時改為休眠。
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

  # 從休眠恢復後 _LID 仍是「關」,logind 會一再睡眠;見 WA-002。恢復必經
  # 電源鍵,蓋子一定是開的。驅動在輸入裝置首次開啟時才回報初始狀態,所以
  # open 要保留到下次睡眠前才還原。
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

  # 休眠恢復後觸控板不會重新列舉;見 WA-003。resumeCommands 的 PATH 只有
  # coreutils、grep、sed 與 systemd。
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

  desktop'.power-profiles-daemon.enable = true;
  desktop'.upower.enable = true;
}
