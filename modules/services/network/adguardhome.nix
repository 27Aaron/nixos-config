{
  config,
  lib,
  ...
}:
let
  cfg = config.services'.adguardhome;
in
{
  options.services'.adguardhome = {
    enable = lib.mkEnableOption "AdGuard Home as the LAN-facing DNS server, forwarding to mosdns";

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = ''
        Web UI port. This is NOT enforced by Nix — set the same port in
        the first-run wizard, otherwise the firewall-opened port points
        nowhere.
      '';
    };

    dnsUpstream = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:5335";
      description = "Upstream DNS server AdGuard Home forwards to (mosdns).";
    };
  };

  config = lib.mkIf cfg.enable {
    # 首次設定(網頁精靈,http://<位址>:<webPort>/):`settings` 必須保持 null,
    # 否則模組先種了 yaml,精靈頁永不出現,AGH 會在 `users` 空著的情況下以
    # 未啟用驗證的狀態執行。網頁與 DNS 都選「所有介面」,連接埠分別是 webPort
    # 與 53,上游填 127.0.0.1:5335(mosdns),bootstrap 223.5.5.5。過濾器建議
    # https://anti-AD.net/easylist.txt,快取保持預設(快取層在 mosdns)。精靈
    # 的 bind 檢查會撞到自己佔的埠,選特定介面過不去。
    #
    # 不需要另外登記持久化:上游模組用 DynamicUser,狀態在
    # /var/lib/private/AdGuardHome,已由 hardware'.persistence 涵蓋;再 bind
    # mount 會弄壞 systemd 的目錄搬移(EXDEV)。
    services.adguardhome.enable = true;

    systemd.services.adguardhome = {
      after = [ "mosdns.service" ];
      wants = [ "mosdns.service" ];
    };

    # 網頁 UI 不限來源,信任區網。
    networking.firewall = {
      allowedTCPPorts = [
        53
        cfg.webPort
      ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
