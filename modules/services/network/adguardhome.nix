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
    # ── 首次設定清單 ─────────────────────────────────────────────
    # 完全由網頁 UI 設定:`settings` 必須保持 null,否則模組先種了
    # yaml、精靈頁永遠不出現,AGH 會在 `users` 空著的情況下以未啟用
    # 驗證的狀態執行。
    #
    # 1. 精靈頁(http://<位址>:<webPort>/):
    #      網頁管理介面:介面選「所有介面」(0.0.0.0),連接埠 = webPort(3000)
    #      DNS 伺服器:  介面選「所有介面」(0.0.0.0),連接埠 53
    #      管理者帳號:  自行設定憑證
    #      上游:        127.0.0.1:5335        (mosdns)
    #      bootstrap:   223.5.5.5, 119.29.29.29
    #    精靈頁的怪癖:DNS 介面選特定介面會因為精靈實例自己佔著連接埠而
    #    通不過 bind 檢查;這裡 DNS 本來就要對區網監聽,選「所有介面」
    #    正是想要的結果,靠防火牆限制來源。
    #
    # 2. 建議的過濾器(UI,過濾器 → DNS 封鎖清單):
    #      https://anti-AD.net/easylist.txt
    #
    # 3. 快取保持精靈頁預設(TTL 透傳、不開樂觀快取);有意義的快取層
    #    在 mosdns。
    #
    # 注意:不需要另外登記持久化。上游模組使用 DynamicUser +
    # StateDirectory=AdGuardHome,狀態在 /var/lib/private/AdGuardHome,
    # 已由 hardware'.persistence 的預設持久化涵蓋;把 /var/lib/AdGuardHome
    # 另外 bind mount 會弄壞 systemd 的目錄搬移(EXDEV)。
    services.adguardhome.enable = true;

    systemd.services.adguardhome = {
      after = [ "mosdns.service" ];
      wants = [ "mosdns.service" ];
    };

    # DNS 對區網提供;網頁 UI 也開在防火牆,來源限制交給區網本身。
    networking.firewall = {
      allowedTCPPorts = [
        53
        cfg.webPort
      ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
