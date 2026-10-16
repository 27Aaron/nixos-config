{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.dae;

  # 節點、訂閱與出口組的憑據在 nix-secrets 的 services/dae.yaml,以同名鍵存放。
  # sops 逐鍵解密為 .dae,並與其他片段歸集到同一目錄供 dae include。
  secretFile = "${inputs.secrets}/services/dae.yaml";

  secretFragments = [
    "node"
    "subscription"
    "group"
  ];

  configEntries = [
    {
      name = "config.dae";
      path = pkgs.writeText "config.dae" ''
        include {
          config.d/*.dae
        }
        global {
          tproxy_port: 12345
          log_level: info
          check_interval: 30s
          check_tolerance: 50ms
          wan_interface: auto
          dial_mode: domain
          auto_config_kernel_parameter: true
          tls_implementation: utls
          utls_imitate: ios_auto
        }
      '';
    }
    {
      name = "config.d/dns.dae";
      path = pkgs.writeText "dns.dae" ''
        dns {
          ipversion_prefer: 4
          upstream {
            alidns: 'udp://dns.alidns.com:53'
            remote: 'tcp+udp://dns.google'
            pollution: 'quic://unfiltered.adguard-dns.com'
          }
          routing {
            request {
              qname(geosite:cn) -> alidns
              fallback: remote
            }
            response {
              upstream(pollution) -> accept
              !qname(geosite:cn) && ip(geoip:private) -> pollution
              fallback: accept
            }
          }
        }
      '';
    }
    {
      name = "config.d/route.dae";
      path = pkgs.writeText "route.dae" ''
        routing {
          dip(geoip:private) -> direct

          # 命令列與桌面版的全部連接都走 ai,兜住域名規則沒列到的端點。
          pname(claude, claude-desktop) -> ai

          # Anthropic 與 Claude 的主要域名及其 API、認證、CDN 等子域名。
          domain(suffix: anthropic.com, suffix: clau.de, suffix: claude.ai,
            suffix: claude.app, suffix: claude.com, suffix: claudemcpclient.com,
            suffix: claudemcpcontent.com, suffix: claudeusercontent.com) -> ai

          # Anthropic 網頁使用的獨立 CDN 主機,不屬於上面的主域名。
          domain(full: servd-anthropic-website.b-cdn.net,
            full: anthropic.com.cdn.cloudflare.net) -> ai

          # Anthropic 網頁引用的認證與內容服務。
          domain(full: anthropic.auth0.com, full: anthropic-com.ghost.io) -> ai

          # Claude Code 的遙測、錯誤回報與反欺詐服務,關鍵詞用於涵蓋新增端點。
          domain(full: http-intake.logs.us5.datadoghq.com,
            full: browser-intake-us5-datadoghq.com,
            suffix: sentry.io, suffix: statsigapi.net,
            keyword: datadog, keyword: sentry, keyword: sift) -> ai

          # Anthropic 網頁客戶端使用的客服與統計依賴。
          domain(suffix: intercom.io, suffix: intercomcdn.com,
            full: cdn.usefathom.com) -> ai

          # Anthropic 自有的地址段,只保留已包含較窄網段的範圍。
          dip(160.79.104.0/21, '2607:6bc0::/32') -> ai

          domain(geosite:category-ai-!cn) -> ai

          domain(geosite:telegram) -> tg
          dip(geoip:telegram) -> tg
          domain(geosite:google) -> google

          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct

          fallback: proxy
        }
      '';
    }
  ]
  ++ map (name: {
    name = "config.d/${name}.dae";
    path = config.sops.secrets."${name}.dae".path;
  }) secretFragments;

  configDir = pkgs.linkFarm "dae-config" configEntries;
in
{
  options.services'.dae = {
    enable = lib.mkEnableOption "dae transparent proxy";
  };

  config = lib.mkIf cfg.enable {
    # 解密依賴 core'.sops 提供的 age 私鑰。
    core'.sops.enable = true;

    sops.secrets = lib.genAttrs (map (name: "${name}.dae") secretFragments) (name: {
      sopsFile = secretFile;
      key = lib.removeSuffix ".dae" name;
    });

    services.dae = {
      enable = true;
      package = pkgs.dae;
      configFile = "${configDir.outPath}/config.dae";

      openFirewall = {
        enable = true;
        port = 12345;
      };
    };

    # 上游只把入口配置複製進憑據目錄,include 的 config.d 會找不到。改為直接讀取
    # 歸集後的目錄,validate 與 run 一起改。
    systemd.services.dae.serviceConfig = {
      LoadCredential = lib.mkForce [ ];
      ExecStartPre = lib.mkForce [
        ""
        "${lib.getExe pkgs.dae} validate -c ${configDir.outPath}/config.dae"
      ];
      ExecStart = lib.mkForce [
        ""
        "${lib.getExe pkgs.dae} run --disable-timestamp -c ${configDir.outPath}/config.dae"
      ];
    };
  };
}
