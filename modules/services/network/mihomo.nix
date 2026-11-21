{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.mihomo;

  secretFile = "${inputs.secrets}/services/mihomo.yaml";

  testUrl = "http://cp.cloudflare.com/generate_204";

  chinaDNS = [
    "https://dns.alidns.com/dns-query#DIRECT"
    "https://doh.pub/dns-query#DIRECT"
  ];
  foreignDNS = [
    "https://dns.cloudflare.com/dns-query#Proxies"
    "https://dns.google/dns-query#Proxies"
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

  iconBase = "https://github.com/Koolson/Qure/raw/master/IconSet/Color";

  regionGroup = region: icon: filter: {
    name = region;
    inherit filter;
    type = "url-test";
    url = testUrl;
    interval = 300;
    timeout = 3000;
    tolerance = 20;
    lazy = true;
    max-failed-times = 3;
    expected-status = "204";
    empty-fallback = "REJECT";
    include-all = true;
    exclude-type = "DIRECT";
    hidden = true;
    icon = "${iconBase}/${icon}.png";
  };

  serviceGroup = name: icon: proxies: {
    inherit name proxies;
    type = "select";
    url = testUrl;
    interval = 600;
    timeout = 3000;
    max-failed-times = 3;
    lazy = true;
    icon = "${iconBase}/${icon}.png";
  };

  regionFallback = [
    "Manual"
    "HK"
    "JP"
    "KR"
    "SG"
    "TW"
    "US"
  ];
  aiFallback = [
    "Manual"
    "JP"
    "KR"
    "SG"
    "TW"
    "US"
  ];

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
    secret = config.sops.placeholder.mihomo-secret;
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
      ipv6 = true;
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      fake-ip-filter = [ "rule-set:private" ];
    };

    proxy-providers.subscription = {
      type = "http";
      url = config.sops.placeholder.mihomo-subscription;
      interval = 3600;
      path = "./providers/subscription.yaml";
      health-check = {
        enable = true;
        url = testUrl;
        interval = 600;
        timeout = 3000;
        lazy = true;
      };
    };

    proxy-groups = [
      {
        name = "Manual";
        type = "select";
        include-all = true;
        icon = "https://raw.githubusercontent.com/shindgew/WHATSINStash/main/icon/fallback.png";
      }
      (serviceGroup "AI" "ChatGPT" aiFallback)
      (serviceGroup "Google" "Google_Search" regionFallback)
      (serviceGroup "Telegram" "Telegram" regionFallback)
      (serviceGroup "Twitter" "Twitter" regionFallback)
      (serviceGroup "Proxies" "Proxy" regionFallback)
    ]
    ++ [
      (regionGroup "HK" "Hong_Kong" "(?i)(🇭🇰|香港|Hong.?Kong|\\bHKG\\b|\\bHK\\b)")
      (regionGroup "JP" "Japan" "(?i)(🇯🇵|日本|东京|東京|大阪|Japan|\\bJPN\\b|\\bJP\\b)")
      (regionGroup "KR" "Korea" "(?i)(🇰🇷|韩国|韓國|首尔|首爾|Korea|Seoul|\\bKOR\\b|\\bKR\\b)")
      (regionGroup "SG" "Singapore" "(?i)(🇸🇬|新加坡|狮城|Singapore|\\bSGP\\b|\\bSG\\b)")
      (regionGroup "TW" "Taiwan" "(?i)(🇹🇼|台湾|台灣|臺灣|Taiwan|\\bTWN\\b|\\bTW\\b)")
      (regionGroup "US" "United_States" "(?i)(🇺🇸|美国|美國|United.?States|America|\\bUSA\\b|\\bUS\\b)")
    ];

    rule-providers = {
      ads =
        mrsProvider "ads" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/category-ads-all.mrs";

      AI =
        mrsProvider "AI" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/category-ai-!cn.mrs";
      Anthropic =
        mrsProvider "anthropic" "domain"
          "https://fastly.jsdelivr.net/gh/27Aaron/ProxyRules@custom/Rules/Anthropic/Anthropic.mrs";
      Anthropic_ip =
        mrsProvider "anthropic_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/27Aaron/ProxyRules@custom/Rules/Anthropic/Anthropic.ipcidr.mrs";
      AppleAI =
        mrsProvider "appleai" "domain"
          "https://fastly.jsdelivr.net/gh/27Aaron/ProxyRules@custom/Rules/AppleAI/AppleAI.mrs";

      ApplePush =
        mrsProvider "applepush" "domain"
          "https://fastly.jsdelivr.net/gh/27Aaron/ProxyRules@custom/Rules/ApplePush/ApplePush.mrs";
      ApplePush_ip =
        mrsProvider "applepush_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/27Aaron/ProxyRules@custom/Rules/ApplePush/ApplePush.ipcidr.mrs";

      private =
        mrsProvider "private" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/private.mrs";
      private_ip =
        mrsProvider "private_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/private.mrs";
      proxy =
        mrsProvider "proxy" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/geolocation-!cn.mrs";
      google =
        mrsProvider "google" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/google.mrs";
      google_ip =
        mrsProvider "google_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/google.mrs";
      telegram =
        mrsProvider "telegram" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/telegram.mrs";
      telegram_ip =
        mrsProvider "telegram_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/telegram.mrs";
      twitter =
        mrsProvider "twitter" "domain"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/twitter.mrs";
      twitter_ip =
        mrsProvider "twitter_ip" "ipcidr"
          "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/twitter.mrs";
    };

    rules = [
      "RULE-SET,ads,REJECT"
      "AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((OR,((GEOSITE,cn),(GEOIP,CN,no-resolve)))))),REJECT"
      "DOMAIN-KEYWORD,datadog,AI"
      "DOMAIN-KEYWORD,sentry,AI"
      "DOMAIN-KEYWORD,sift,AI"
      "DOMAIN-KEYWORD,siri,AI"
      "RULE-SET,Anthropic,AI"
      "RULE-SET,Anthropic_ip,AI,no-resolve"
      "RULE-SET,AppleAI,AI"
      "RULE-SET,AI,AI"
      "RULE-SET,ApplePush,Proxies"
      "RULE-SET,ApplePush_ip,Proxies,no-resolve"
      "RULE-SET,google,Google"
      "RULE-SET,google_ip,Google,no-resolve"
      "RULE-SET,telegram,Telegram"
      "RULE-SET,telegram_ip,Telegram,no-resolve"
      "RULE-SET,twitter,Twitter"
      "RULE-SET,twitter_ip,Twitter,no-resolve"
      "RULE-SET,private,DIRECT"
      "RULE-SET,private_ip,DIRECT,no-resolve"
      "GEOSITE,cn,DIRECT"
      "GEOIP,CN,DIRECT,no-resolve"
      "RULE-SET,proxy,Proxies"
      "MATCH,Proxies"
    ];
  };
in
{
  options.services'.mihomo = {
    enable = lib.mkEnableOption "mihomo proxy with the zashboard web UI";

    port = lib.mkOption {
      type = lib.types.port;
      default = 7890;
      description = "Mixed (HTTP/SOCKS) proxy port.";
    };

    controllerPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "external-controller port; zashboard is served on the same port under /ui.";
    };

    allowLan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Listen on all interfaces and open the firewall, so LAN clients can
        use this host as their proxy and reach the dashboard.
      '';
    };

    tun.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Take over this host's routing and DNS with TUN and fake-ip.
        Turn off for a mixed-port proxy that should not redirect the
        host's own traffic.
      '';
    };

    ipv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether mihomo resolves AAAA and connects over IPv6. Only turn on
        when the host itself has working IPv6 at the kernel level.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      mihomo-subscription = {
        sopsFile = secretFile;
        key = "subscription";
        restartUnits = [ "mihomo.service" ];
      };
      mihomo-secret = {
        sopsFile = secretFile;
        key = "secret";
        restartUnits = [ "mihomo.service" ];
      };
    };

    sops.templates."mihomo.yaml" = {
      content = mihomoConfig;
      restartUnits = [ "mihomo.service" ];
    };

    services.mihomo = {
      enable = true;
      configFile = config.sops.templates."mihomo.yaml".path;
      webui = pkgs.zashboard;
      tunMode = cfg.tun.enable;
    };

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
    };

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
