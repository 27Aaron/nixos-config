{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.dae;

  # 憑證位於 nix-secrets 的 services/dae.yaml,sops 將每個鍵解密成同名的
  # .dae 片段,與其餘片段放在同一目錄供 include。
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
          # domain 在快取未命中時會明文直連探測域名(引導解析器預設為
          # 119.29.29.29 與 223.5.5.5);domain++ 跳過這次探測,仍按嗅探到
          # 的域名重分流。
          dial_mode: domain++
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
            alidns: 'https://223.5.5.5/dns-query'
            remote: 'https://1.1.1.1/dns-query'
          }
          routing {
            request {
              qtype(https) -> reject
              qname(geosite:category-ads-all) -> reject
              qname(geosite:cn) -> alidns
              fallback: remote
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

          pname(claude, .claude-wrapped, claude-desktop, chrome) -> ai

          domain(suffix: anthropic.com, suffix: clau.de, suffix: claude.ai,
            suffix: claude.app, suffix: claude.com, suffix: claudemcpclient.com,
            suffix: claudemcpcontent.com, suffix: claudeusercontent.com) -> ai

          # 網頁用的另一個 CDN,不在上面的主域名之下。
          domain(full: servd-anthropic-website.b-cdn.net,
            full: anthropic.com.cdn.cloudflare.net) -> ai

          domain(full: anthropic.auth0.com, full: anthropic-com.ghost.io) -> ai

          # Claude Code 的遙測、錯誤回報與反欺詐;keyword 罩住之後新增的端點。
          domain(full: http-intake.logs.us5.datadoghq.com,
            full: browser-intake-us5-datadoghq.com,
            suffix: sentry.io, suffix: statsigapi.net,
            keyword: datadog, keyword: sentry, keyword: sift) -> ai

          domain(suffix: intercom.io, suffix: intercomcdn.com,
            full: cdn.usefathom.com) -> ai

          dip(160.79.104.0/21, '2607:6bc0::/32') -> ai

          domain(geosite:category-ai-!cn) -> ai

          domain(geosite:telegram) -> tg
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

  # dae 要求被 include 的檔案位於入口設定目錄下,且群組不可寫、其他人不可讀;
  # store 檔案為 0444 會被拒絕,linkFarm 只作為複製來源。
  configDir = pkgs.linkFarm "dae-config" configEntries;

  # 啟動時複製到 /etc/dae 並設為 0600。
  runtimeConfig = "/etc/dae/config.dae";

  assembleConfig = pkgs.writeShellScript "assemble-dae-config" ''
    set -euo pipefail
    # /etc/dae 可能是指向 store 的符號連結,先換成可寫目錄。
    rm -rf /etc/dae
    install -d -m 0700 /etc/dae/config.d
    install -m 0600 ${configDir}/config.dae /etc/dae/config.dae
    install -m 0600 ${configDir}/config.d/*.dae /etc/dae/config.d/
  '';
in
{
  options.services'.dae = {
    enable = lib.mkEnableOption "dae transparent proxy";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs (map (name: "${name}.dae") secretFragments) (name: {
      sopsFile = secretFile;
      key = lib.removeSuffix ".dae" name;
      restartUnits = [ "dae.service" ];
    });

    services.dae = {
      enable = true;
      package = pkgs.dae;
      configFile = "${configDir}/config.dae";

      # 是否真的需要開放這個埠尚未驗證,見 WORKAROUNDS.md 的 WA-014。
      openFirewall = {
        enable = true;
        port = 12345;
      };
    };

    systemd.services.dae = {
      # 片段要等 sops 解密後才存在,組裝必須排在它後面。
      after = [ "sops-install-secrets.service" ];
      serviceConfig = {
        # 上游模組只複製入口設定,include 的 config.d 會遺失,因此改為自行組裝。
        # 移除條件見 WORKAROUNDS.md 的 WA-009。
        LoadCredential = lib.mkForce [ ];
        ExecStartPre = lib.mkForce [
          ""
          assembleConfig
          "${lib.getExe pkgs.dae} validate -c ${runtimeConfig}"
        ];
        ExecStart = lib.mkForce [
          ""
          "${lib.getExe pkgs.dae} run --disable-timestamp -c ${runtimeConfig}"
        ];
      };
    };
  };
}
