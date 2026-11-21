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
        Web UI port. AdGuard Home is started with
        `--web-addr 0.0.0.0:<port>`, which overrides the config file,
        and the firewall allows that port. In the first-run wizard pick
        all interfaces and this same port.
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
    # 未啟用驗證的狀態執行。二進位預設聽 3000,防火牆開的是 webPort,所以用
    # --web-addr 把精靈綁在 0.0.0.0:webPort,否則頁面打不開。網頁與 DNS 都
    # 選「所有介面」,連接埠分別是 webPort 與 53,上游填
    # 127.0.0.1:5335(mosdns),bootstrap 223.5.5.5。過濾器建議
    # https://anti-AD.net/easylist.txt,快取保持預設(快取層在 mosdns)。精靈
    # 的 bind 檢查會撞到自己佔的埠,選特定介面過不去。
    #
    # 不需要另外登記持久化:上游模組用 DynamicUser,狀態在
    # /var/lib/private/AdGuardHome,已由 hardware'.persistence 涵蓋;再 bind
    # mount 會弄壞 systemd 的目錄搬移(EXDEV)。
    services.adguardhome = {
      enable = true;
      extraArgs = [
        "--web-addr"
        "0.0.0.0:${toString cfg.webPort}"
      ];
    };

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
