{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.mihomo-proxy;

  tunBlock = lib.optionalString cfg.tun.enable ''
    tun:
      enable: true
      stack: system
      auto-route: true
      strict-route: true
      auto-redirect: true
      auto-detect-interface: true
      dns-hijack:
        - any:53
        - tcp://any:53
      # 區網與鏈路本地位址不進 TUN,SSH 與內部服務才不會被繞進代理。
      route-exclude-address:
        - 10.0.0.0/8
        - 100.64.0.0/10
        - 127.0.0.0/8
        - 169.254.0.0/16
        - 172.16.0.0/12
        - 192.0.0.0/24
        - 192.0.2.0/24
        - 192.168.0.0/16
        - 198.51.100.0/24
        - 203.0.113.0/24
        - 224.0.0.0/4
        - 255.255.255.255/32
        - ::1/128
        - fc00::/7
        - fe80::/10
        - ff00::/8
        - ::ffff:0:0:0/96
  '';

  # 種子內容不含訂閱連結等機密,可以放進所有人可讀的 store;控制器密鑰
  # 是跟著種子走的固定值。
  initialConfig = pkgs.writeText "mihomo-proxy-initial.yaml" ''
    # 首次部署自動生成,之後以這份檔案為準,直接手動編輯,rebuild 不會覆蓋。
    # 修改後執行 `systemctl restart mihomo` 生效。
    mixed-port: ${toString cfg.port}
    allow-lan: ${if cfg.allowLan then "true" else "false"}
    bind-address: "${if cfg.allowLan then "*" else "127.0.0.1"}"
    mode: rule
    log-level: info
    ipv6: ${if cfg.ipv6 then "true" else "false"}
    external-controller: ${
      if cfg.allowLan then "0.0.0.0" else "127.0.0.1"
    }:${toString cfg.controllerPort}
    secret: "27Aaron"
    profile:
      store-selected: true
      store-fake-ip: true

    # GEOSITE/GEOIP 規則要用的 geo 檔;jsdelivr 鏡像在直連網路也拉得到。
    geox-url:
      geoip: https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat
      geosite: https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat
      mmdb: https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.metadb
    geo-auto-update: true
    geo-update-interval: 24

    # 加節點只需在下面貼 proxies:,或改用 proxy-providers 訂閱;Proxy 群組的
    # include-all 會自動帶入,群組本身不用動。DIRECT 先放著當保底,沒有節點
    # 也開得起來。
    # proxies:
    #   - name: my-node
    #     type: ss
    #     server: example.com
    #     port: 8388
    #     cipher: aes-256-gcm
    #     password: "secret"
    proxy-groups:
      - name: Proxy
        type: select
        include-all: true
        proxies:
          - DIRECT

    ${tunBlock}
    # behavior 必填:geosite 的 .mrs 是 domain 集合,geoip 的是 ipcidr 集合,
    # 兩種二進位格式不能混用。
    rule-providers:
      ads:
        type: http
        behavior: domain
        format: mrs
        url: https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/category-ads-all.mrs
        interval: 86400
        path: ./ruleset/ads.mrs
      private:
        type: http
        behavior: domain
        format: mrs
        url: https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/private.mrs
        interval: 86400
        path: ./ruleset/private.mrs
      private_ip:
        type: http
        behavior: ipcidr
        format: mrs
        url: https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/private.mrs
        interval: 86400
        path: ./ruleset/private_ip.mrs

    dns:
      enable: true
      ipv6: ${if cfg.ipv6 then "true" else "false"}
      enhanced-mode: fake-ip
      fake-ip-range: 198.18.0.1/16
      fake-ip-filter:
        - rule-set:private
      default-nameserver:
        - 223.5.5.5
        - 119.29.29.29
      nameserver:
        - https://dns.cloudflare.com/dns-query
        - https://dns.google/dns-query

    # 基本規則:擋廣告與境外 QUIC、私有網域直連,其餘全部走 Proxy;要更
    # 細的分流再自己往上加。
    rules:
      # > Ads
      - RULE-SET,ads,REJECT
      # > Block foreign QUIC
      - AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((OR,((GEOSITE,cn),(GEOIP,CN,no-resolve)))))),REJECT
      # > Private
      - RULE-SET,private,DIRECT
      - RULE-SET,private_ip,DIRECT,no-resolve
      # > Final
      - MATCH,Proxy
  '';
in
{
  options.services'.mihomo-proxy = {
    enable = lib.mkEnableOption "mihomo as a plain global proxy (basic ad and private rules, everything else into a single Proxy group); the config is seeded once at /etc/mihomo/config.yaml and hand-edited afterwards";

    port = lib.mkOption {
      type = lib.types.port;
      default = 7890;
      description = ''
        Mixed (HTTP/SOCKS) proxy port; baked into the seeded config and
        opened in the firewall when allowLan is on. After the seed exists,
        change the port in the file itself.
      '';
    };

    controllerPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = ''
        external-controller port; zashboard is served on the same port under
        /ui. Baked into the seeded config and opened in the firewall when
        allowLan is on.
      '';
    };

    allowLan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Listen on all interfaces and open the firewall, so LAN clients can
        use this host as their proxy and reach the dashboard. Also baked into
        the seeded config.
      '';
    };

    tun.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether the seeded config enables TUN and the service is granted
        CAP_NET_ADMIN. After the seed exists the file is authoritative; this
        only matters for fresh installs.
      '';
    };

    ipv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether mihomo resolves AAAA and connects over IPv6, baked into the
        seeded config. Only turn on when the host itself has working IPv6 at
        the kernel level; otherwise connections black-hole. After the seed
        exists, change it in the file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # 與 mihomo.nix 分工:那份是完整分流規則的宣告式設定;這份種下基本規
    # 則加單一 Proxy 群組,之後由手動編輯維護。兩者同時啟用
    # 會在 configFile 等選項直接合併衝突,錯誤訊息會點名兩個檔案,因此
    # 不另加互斥斷言。

    # 只種一次,之後 /etc/mihomo/config.yaml 是權威設定,rebuild 與重開機都
    # 不會覆寫。上游模組以 LoadCredential 在啟動時請 root 讀取 configFile,
    # 再交給 DynamicUser 的 mihomo,因此 0600 的檔案與 0700 的目錄不影響
    # 服務讀取;訂閱連結等機密只存在 LUKS 加密的持久卷上,不走 sops。
    system.activationScripts.mihomo-proxy-initial-config.text = ''
      if [ ! -e /etc/mihomo/config.yaml ]; then
        install -d -m 0700 /etc/mihomo
        install -D -m 0600 ${initialConfig} /etc/mihomo/config.yaml
      fi
    '';

    services.mihomo = {
      enable = true;
      configFile = "/etc/mihomo/config.yaml";
      webui = pkgs.zashboard;
      tunMode = cfg.tun.enable;
    };

    # 持久化整個目錄而非單一檔案:編輯器以 rename() 原子寫入,單檔 bind
    # mount 會以 EBUSY 失敗。檔案含訂閱連結與控制器密鑰,目錄維持 0700。
    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/etc/mihomo";
        mode = "0700";
      }
    ];

    networking.firewall = lib.mkIf cfg.allowLan {
      allowedTCPPorts = [
        cfg.port
        cfg.controllerPort
      ];
    };

    # 不需要另外登記持久化:上游模組用 DynamicUser,狀態在
    # /var/lib/private/mihomo,已由 hardware'.persistence 涵蓋。
  };
}
