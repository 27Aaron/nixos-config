{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.mihomo-lite;

  testUrl = "http://cp.cloudflare.com/generate_204";

  chinaDNS = [
    "https://dns.alidns.com/dns-query#DIRECT"
    "https://doh.pub/dns-query#DIRECT"
  ];
  foreignDNS = [
    "https://dns.cloudflare.com/dns-query#Proxy"
    "https://dns.google/dns-query#Proxy"
  ];

  tunExcludes = [
    "10.0.0.0/8"
    "100.64.0.0/10"
    "127.0.0.0/8"
    "169.254.0.0/16"
    "172.16.0.0/12"
    "192.0.0.0/24"
    "192.0.2.0/24"
    "192.168.0.0/16"
    "198.51.100.0/24"
    "203.0.113.0/24"
    "224.0.0.0/4"
    "255.255.255.255/32"
    "::1/128"
    "fc00::/7"
    "fe80::/10"
    "ff00::/8"
    "::ffff:0:0:0/96"
  ];

  # behavior 是必填欄位,缺少會在啟動時直接失敗;geosite 的 .mrs 是
  # domain 集合,geoip 的 .mrs 是 ipcidr 集合,兩種二進位格式不能混用。
  mrsProvider = name: behavior: url: {
    inherit name behavior url;
    type = "http";
    format = "mrs";
    interval = 86400;
    path = "./ruleset/${name}.mrs";
  };

  mihomoConfig = lib.generators.toYAML { } {
    mixed-port = cfg.port;
    allow-lan = cfg.allowLan;
    bind-address = if cfg.allowLan then "*" else "127.0.0.1";
    mode = "rule";
    log-level = "info";
    ipv6 = cfg.ipv6;
    unified-delay = true;
    tcp-concurrent = true;
    keep-alive-idle = 30;
    keep-alive-interval = 15;
    external-controller =
      if cfg.allowLan then
        "0.0.0.0:${toString cfg.controllerPort}"
      else
        "127.0.0.1:${toString cfg.controllerPort}";
    secret = "27Aaron";
    profile.store-selected = true;
    profile.store-fake-ip = cfg.tun.enable;

    tun = lib.optionalAttrs cfg.tun.enable {
      enable = true;
      stack = "system";
      auto-route = true;
      strict-route = true;
      auto-redirect = true;
      auto-detect-interface = true;
      dns-hijack = [
        "any:53"
        "tcp://any:53"
      ];
      # 區網與鏈路本地位址不進 TUN,SSH 與內部服務才不會被繞進代理。
      route-exclude-address = tunExcludes;
    };

    geox-url = {
      geoip = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat";
      geosite = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat";
      mmdb = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.metadb";
    };
    geo-auto-update = true;
    geo-update-interval = 24;

    ntp = {
      enable = true;
      write-to-system = false;
      server = "ntp.aliyun.com";
      port = 123;
      interval = 60;
    };

    sniffer = {
      enable = true;
      sniff = {
        HTTP = {
          ports = [
            "80"
            "8080-8880"
          ];
          override-destination = true;
        };
        TLS.ports = [
          "443"
          "8443"
        ];
        QUIC.ports = [
          "443"
          "8443"
        ];
      };
      skip-domain = [
        "Mijia Cloud"
        "+.push.apple.com"
        "captive.apple.com"
      ];
    };

    dns = {
      enable = true;
      ipv6 = cfg.ipv6;
      default-nameserver = [
        "223.5.5.5"
        "119.29.29.29"
      ];
      proxy-server-nameserver = chinaDNS;
      nameserver = foreignDNS;
      nameserver-policy."geosite:cn" = chinaDNS;
      direct-nameserver = [
        "223.5.5.5"
        "119.29.29.29"
      ];
      use-system-hosts = true;
      cache-algorithm = "arc";
    }
    // lib.optionalAttrs cfg.tun.enable {
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      fake-ip-filter = [ "rule-set:private" ];
    };

    # 沒有訂閱。節點之後直接寫進種下的檔案,include-all 會帶進 Proxy。
    proxy-groups = [
      {
        name = "Proxy";
        type = "select";
        include-all = true;
        url = testUrl;
        icon = "https://github.com/Koolson/Qure/raw/master/IconSet/Color/Proxy.png";
        proxies = [ "DIRECT" ];
      }
    ];

    rule-providers = {
      ads =
        mrsProvider "ads" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/category-ads-all.mrs";
      private =
        mrsProvider "private" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/private.mrs";
      private_ip =
        mrsProvider "private_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/private.mrs";
    };

    # 擋廣告與境外 QUIC,私有網域與中國大陸直連,其餘全部走 Proxy。
    rules = [
      "RULE-SET,ads,REJECT"
      "AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((OR,((GEOSITE,cn),(GEOIP,CN,no-resolve)))))),REJECT"
      "RULE-SET,private,DIRECT"
      "RULE-SET,private_ip,DIRECT,no-resolve"
      "GEOSITE,cn,DIRECT"
      "GEOIP,CN,DIRECT,no-resolve"
      "MATCH,Proxy"
    ];
  };

  # 檔首說明留給之後手動改的人。toYAML 在這版 nixpkgs 就是 toJSON,
  # 種下去會是一行;這份是給人改的,建置時轉成區塊式 YAML。屬性集沒有
  # 書寫順序,鍵會按名稱排序。
  initialConfig =
    pkgs.runCommand "mihomo-lite-initial.yaml"
      {
        nativeBuildInputs = [ pkgs.yj ];
        passAsFile = [ "json" ];
        json = mihomoConfig;
      }
      ''
        {
          cat <<'EOF'
        # 首次部署自動生成,之後以這份檔案為準,直接手動編輯,rebuild 不會覆蓋。
        # 修改後執行 `systemctl restart mihomo` 生效。
        # 加節點寫在 proxies: 或 proxy-providers:;Proxy 群組的 include-all 會帶入。
        EOF
          yj -jy < "$jsonPath"
        } > "$out"
      '';
in
{
  options.services'.mihomo-lite = {
    enable = lib.mkEnableOption "mihomo as a plain global proxy (basic ad, private, and China-direct rules, everything else into a single Proxy group); the config is seeded once at /etc/mihomo/config.yaml and hand-edited afterwards";

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
    # 與 mihomo.nix 分工:那份用 sops 的訂閱做完整分流;這份種下同一套基礎
    # 設定,但只有廣告、私有網域與中國大陸直連,以及單一 Proxy 群組,之後手動編輯。
    # 兩者同時啟用會在 configFile 等選項直接合併衝突,錯誤訊息會點名兩個
    # 檔案,因此不另加互斥斷言。

    # 只種一次,之後 /etc/mihomo/config.yaml 是權威設定,rebuild 與重開機都
    # 不會覆寫。上游模組以 LoadCredential 在啟動時請 root 讀取 configFile,
    # 再交給 DynamicUser 的 mihomo,因此 0600 的檔案與 0700 的目錄不影響
    # 服務讀取;訂閱連結等機密只存在 LUKS 加密的持久卷上,不走 sops。
    # 種子不走 activationScripts:live switch 時 preservation 的 bind mount
    # 晚於 activation 啟動,種下的檔案會被掛載遮蔽,LoadCredential 讀不到;
    # 改用 oneshot,明確排在掛載之後、mihomo 之前。
    systemd.services.mihomo-config = {
      description = "Seed the hand-edited mihomo config once";
      wantedBy = [ "mihomo.service" ];
      before = [ "mihomo.service" ];
      after = lib.optionals config.hardware'.persistence.enable [ "etc-mihomo.mount" ];
      wants = lib.optionals config.hardware'.persistence.enable [ "etc-mihomo.mount" ];
      path = [ pkgs.coreutils ];
      serviceConfig.Type = "oneshot";
      script = ''
        if [ ! -e /etc/mihomo/config.yaml ]; then
          install -d -m 0700 /etc/mihomo
          install -D -m 0600 ${initialConfig} /etc/mihomo/config.yaml
        fi
      '';
    };

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
