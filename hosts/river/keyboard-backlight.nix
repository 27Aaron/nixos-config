{
  config,
  lib,
  pkgs,
  ...
}:
let
  kmod = "${pkgs.kmod}/bin";
  inherit (config.boot) kernelPackages;

  # 套件自己複製 .ko,跳過 modules_install 的 kmodigest,缺少模組彙整要的
  # .ko.cer;見 WA-025。
  acpiCall = kernelPackages.acpi_call.overrideAttrs (old: {
    installPhase = old.installPhase + ''
      ${lib.getExe pkgs.buildPackages.kmodigest} \
        $out/lib/modules/${kernelPackages.kernel.modDirVersion}/misc/acpi_call.ko
    '';
  });

  # EC 位址與位元取自上游 uniwill-acpi.c:0x78c 的 bit 1 是 KBD_POWER_OFF、
  # bit 4 是 KBD_APPLY、bit 7:5 是亮度,其餘位元保留原值。見 WA-024。
  backlightOff = pkgs.writeShellScript "keyboard-backlight-off" ''
    set -eu
    ${kmod}/modprobe acpi_call
    trap '${kmod}/rmmod acpi_call' EXIT

    call() {
      echo "$1" > /proc/acpi/call
      tr -d '\0' < /proc/acpi/call
    }

    status=$(call '\_SB.INOU.ECRR 0x78c')
    case "$status" in
      0x[0-9a-f] | 0x[0-9a-f][0-9a-f]) ;;
      *)
        echo "keyboard backlight: unexpected EC status: $status" >&2
        exit 1
        ;;
    esac
    call "\_SB.INOU.ECRW 0x78c $(printf '0x%x' $(((status & ~0xf2) | 0x12)))" > /dev/null
  '';
in
{
  # 只在呼叫期間載入:acpi_call 讓 root 能執行任意 ACPI 方法。
  boot.extraModulePackages = [ acpiCall ];

  # EC 每次上電都把燈打開;休眠恢復也是重新上電。
  powerManagement.powerUpCommands = "${backlightOff}";
}
