{ lib }:
let
  metaRules = "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo";

  # behavior 是必填欄位,缺少會在啟動時直接失敗;geosite 的 .mrs 是
  # domain 集合,geoip 的 .mrs 是 ipcidr 集合,兩種二進位格式不能混用。
  mrsProvider = name: behavior: url: {
    inherit name behavior url;
    type = "http";
    format = "mrs";
    interval = 86400;
    path = "./ruleset/${name}.mrs";
  };

  chinaNameservers = [
    "223.5.5.5"
    "119.29.29.29"
  ];

  chinaDNS = [
    "https://dns.alidns.com/dns-query#DIRECT"
    "https://doh.pub/dns-query#DIRECT"
  ];

  # 區網與鏈路本地位址不進 TUN,SSH 與內部服務才不會被繞進代理。
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
in
{
  inherit mrsProvider metaRules;

  testUrl = "http://cp.cloudflare.com/generate_204";

  # 擋廣告與境外 QUIC。
  rejectRuleProviders = {
    ads = mrsProvider "ads" "domain" "${metaRules}/geosite/category-ads-all.mrs";
  };
  rejectRules = [
    "RULE-SET,ads,REJECT"
    "AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((OR,((GEOSITE,cn),(GEOIP,CN,no-resolve)))))),REJECT"
  ];

  # 私有網域與中國大陸直連。
  directRuleProviders = {
    private = mrsProvider "private" "domain" "${metaRules}/geosite/private.mrs";
    private_ip = mrsProvider "private_ip" "ipcidr" "${metaRules}/geoip/private.mrs";
  };
  directRules = [
    "RULE-SET,private,DIRECT"
    "RULE-SET,private_ip,DIRECT,no-resolve"
    "GEOSITE,cn,DIRECT"
    "GEOIP,CN,DIRECT,no-resolve"
  ];

  # 兩種設定檔共用的骨幹。
  base =
    {
      port,
      allowLan,
      controllerPort,
      ipv6,
      tun,
      secret,
      foreignDNS,
    }:
    {
      mixed-port = port;
      allow-lan = allowLan;
      bind-address = if allowLan then "*" else "127.0.0.1";
      mode = "rule";
      log-level = "info";
      inherit ipv6;
      unified-delay = true;
      tcp-concurrent = true;
      keep-alive-idle = 30;
      keep-alive-interval = 15;
      external-controller =
        if allowLan then "0.0.0.0:${toString controllerPort}" else "127.0.0.1:${toString controllerPort}";
      inherit secret;
      profile.store-selected = true;
      profile.store-fake-ip = tun.enable;

      tun = lib.optionalAttrs tun.enable {
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
        inherit ipv6;
        default-nameserver = chinaNameservers;
        proxy-server-nameserver = chinaDNS;
        nameserver = foreignDNS;
        nameserver-policy."geosite:cn" = chinaDNS;
        direct-nameserver = chinaNameservers;
        use-system-hosts = true;
        cache-algorithm = "arc";
      }
      // lib.optionalAttrs tun.enable {
        enhanced-mode = "fake-ip";
        fake-ip-range = "198.18.0.1/16";
        fake-ip-filter = [ "rule-set:private" ];
      };
    };
}
