{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.mihomo;
  inherit (import ./common.nix { inherit lib; })
    testUrl
    mrsProvider
    metaRules
    base
    rejectRuleProviders
    rejectRules
    directRuleProviders
    directRules
    ;

  secretFile = "${inputs.secrets}/services/mihomo.yaml";

  foreignDNS = [
    "https://dns.cloudflare.com/dns-query#Proxies"
    "https://dns.google/dns-query#Proxies"
  ];

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
    "HKG"
    "JPN"
    "KOR"
    "SGP"
    "TWN"
    "USA"
  ];
  aiFallback = [
    "Manual"
    "JPN"
    "KOR"
    "SGP"
    "TWN"
    "USA"
  ];

  customRules = "https://fastly.jsdelivr.net/gh/27Aaron/ProxyRules@custom/Rules";

  serviceRuleProviders = {
    AI = mrsProvider "AI" "domain" "${metaRules}/geosite/category-ai-!cn.mrs";
    Anthropic = mrsProvider "anthropic" "domain" "${customRules}/Anthropic/Anthropic.mrs";
    Anthropic_ip = mrsProvider "anthropic_ip" "ipcidr" "${customRules}/Anthropic/Anthropic.ipcidr.mrs";
    AppleAI = mrsProvider "appleai" "domain" "${customRules}/AppleAI/AppleAI.mrs";

    ApplePush = mrsProvider "applepush" "domain" "${customRules}/ApplePush/ApplePush.mrs";
    ApplePush_ip = mrsProvider "applepush_ip" "ipcidr" "${customRules}/ApplePush/ApplePush.ipcidr.mrs";

    google = mrsProvider "google" "domain" "${metaRules}/geosite/google.mrs";
    google_ip = mrsProvider "google_ip" "ipcidr" "${metaRules}/geoip/google.mrs";
    telegram = mrsProvider "telegram" "domain" "${metaRules}/geosite/telegram.mrs";
    telegram_ip = mrsProvider "telegram_ip" "ipcidr" "${metaRules}/geoip/telegram.mrs";
    twitter = mrsProvider "twitter" "domain" "${metaRules}/geosite/twitter.mrs";
    twitter_ip = mrsProvider "twitter_ip" "ipcidr" "${metaRules}/geoip/twitter.mrs";
  };
  serviceRules = [
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
  ];

  mihomoConfig = lib.generators.toYAML { } (
    base {
      inherit (cfg)
        port
        allowLan
        controllerPort
        ipv6
        tun
        ;
      inherit foreignDNS;
      secret = config.sops.placeholder.mihomo-secret;
    }
    // {
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
        (regionGroup "HKG" "Hong_Kong" "(?i)(🇭🇰|香港|Hong.?Kong|\\bHKG\\b|\\bHK\\b)")
        (regionGroup "JPN" "Japan" "(?i)(🇯🇵|日本|东京|東京|大阪|Japan|\\bJPN\\b|\\bJP\\b)")
        (regionGroup "KOR" "Korea" "(?i)(🇰🇷|韩国|韓國|首尔|首爾|Korea|Seoul|\\bKOR\\b|\\bKR\\b)")
        (regionGroup "SGP" "Singapore" "(?i)(🇸🇬|新加坡|狮城|Singapore|\\bSGP\\b|\\bSG\\b)")
        (regionGroup "TWN" "Taiwan" "(?i)(🇹🇼|台湾|台灣|臺灣|Taiwan|\\bTWN\\b|\\bTW\\b)")
        (regionGroup "USA" "United_States" "(?i)(🇺🇸|美国|美國|United.?States|America|\\bUSA\\b|\\bUS\\b)")
      ];

      rule-providers =
        serviceRuleProviders
        // rejectRuleProviders
        // directRuleProviders
        // {
          proxy = mrsProvider "proxy" "domain" "${metaRules}/geosite/geolocation-!cn.mrs";
        };

      rules =
        rejectRules
        ++ serviceRules
        ++ directRules
        ++ [
          "RULE-SET,proxy,Proxies"
          "MATCH,Proxies"
        ];
    }
  );

  # toYAML 在這版 nixpkgs 就是 toJSON,模板會是一行。sops 讀的是 file,
  # 佔位符在啟動時才替換,所以建置期轉成區塊式 YAML 不用 IFD。
  # yj 不會給 <SOPS:…> 加引號,替換進來的網址或密鑰若含冒號會弄壞 YAML。
  mihomoConfigFile =
    pkgs.runCommand "mihomo.yaml"
      {
        nativeBuildInputs = [ pkgs.yj ];
        passAsFile = [ "json" ];
        json = mihomoConfig;
      }
      ''
        yj -jy < "$jsonPath" \
          | sed -e 's/<SOPS:\([0-9a-f]\{64\}\):PLACEHOLDER>/"<SOPS:\1:PLACEHOLDER>"/g' \
          > "$out"
      '';
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

    gateway = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Act as the gateway for other LAN hosts. Turns on
        `net.ipv4.ip_forward`, and `net.ipv6.conf.all.forwarding` when
        `ipv6` is on, and accepts mihomo's redirected TCP in the
        firewall. Requires `tun.enable`. IPv6 forwarding makes
        systemd-networkd ignore router advertisements unless the
        interface sets `IPv6AcceptRA`.
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
      file = mihomoConfigFile;
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

    networking.firewall = lib.mkMerge [
      (lib.mkIf cfg.allowLan {
        allowedTCPPorts = [
          cfg.port
          cfg.controllerPort
        ];
      })
      # auto-redirect 在 PREROUTING 把區網客戶端的 TCP 轉到本機臨時埠。
      # 那個埠不在 allowedTCPPorts,防火牆會在 INPUT 丟掉;只開 ip_forward
      # 不夠。UDP 與 DNS 則要轉送進 TUN,服務被 ProtectKernelTunables 擋住,
      # 自己寫不了 sysctl。
      (lib.mkIf cfg.gateway {
        extraInputRules = ''
          ct status dnat accept
        '';
      })
    ];

    boot.kernel.sysctl = lib.mkIf cfg.gateway (
      {
        "net.ipv4.ip_forward" = 1;
      }
      // lib.optionalAttrs cfg.ipv6 {
        "net.ipv6.conf.all.forwarding" = 1;
      }
    );

    assertions = [
      {
        assertion = !cfg.gateway || cfg.tun.enable;
        message = "services'.mihomo.gateway requires tun.enable";
      }
    ];

    # 不需要另外登記持久化:上游模組用 DynamicUser,狀態在
    # /var/lib/private/mihomo,已由 hardware'.persistence 涵蓋。
  };
}
