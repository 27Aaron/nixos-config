{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.mosdns;

  stateDir = "/var/lib/mosdns";
  rulesDir = "${stateDir}/rules";

  ruleFiles = {
    "direct-list.txt" =
      "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt";
    "proxy-list.txt" =
      "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt";
    "china-ip.txt" = "https://cdn.jsdelivr.net/gh/gaoyifan/china-operator-ip@ip-lists/china.txt";
    "china-ipv6.txt" = "https://cdn.jsdelivr.net/gh/gaoyifan/china-operator-ip@ip-lists/china6.txt";
  };

  ensureRules = pkgs.writeShellScript "mosdns-ensure-rules" ''
    set -eu
    ${pkgs.coreutils}/bin/mkdir -p ${rulesDir}
    for f in ${lib.concatStringsSep " " (lib.attrNames ruleFiles)}; do
      if [ ! -s ${rulesDir}/$f ]; then
        ${pkgs.coreutils}/bin/touch ${rulesDir}/$f
      fi
    done
  '';

  updateRules = pkgs.writeShellScript "mosdns-update-rules" ''
    set -eu
    rules_dir=${rulesDir}
    tmp=$(${pkgs.coreutils}/bin/mktemp -d)
    trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
    changed=0
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: url: ''
            if ${lib.getExe pkgs.curl} -fsSL --max-time 90 -o "$tmp/${name}" "${url}" && [ -s "$tmp/${name}" ]; then
          if ! ${pkgs.diffutils}/bin/cmp -s "$tmp/${name}" "$rules_dir/${name}"; then
            ${pkgs.coreutils}/bin/install -m 0644 "$tmp/${name}" "$rules_dir/${name}"
            changed=1
          fi
        else
          echo "mosdns-rules: failed to download ${name}" >&2
        fi
      '') ruleFiles
    )}
    if [ "$changed" = 1 ]; then
      echo "mosdns-rules: rules changed, restarting mosdns"
      ${config.systemd.package}/bin/systemctl try-restart mosdns.service || true
    fi
  '';

  # 中國/國外分流:
  #   geosite:cn    -> 中國 UDP DNS(ali + dnspod,並發)
  #   geosite:proxy -> 遠端 DoH。remoteSocks5 有值時經該 SOCKS5 問
  #                    Google 與 Cloudflare;否則直連阿里 DoH。
  #   其餘          -> 先問中國上游;答案沒有 CN IP(被污染/國外主機)
  #                    就改走遠端 DoH。
  #
  # 走 SOCKS 時不用阿里:mihomo 會把阿里判成中國直連,查詢出不了代理。
  # 網域由 SOCKS5 遠端解析,不能加 bootstrap(那是本機 UDP)。
  # udp:// 與 HTTP/3 不支援 socks5。
  remoteForwardArgs =
    if cfg.remoteSocks5 == null then
      {
        upstreams = [
          {
            tag = "ali_doh";
            addr = "https://dns.alidns.com/dns-query";
            bootstrap = "223.5.5.5";
          }
          {
            tag = "ali_doh_ip";
            addr = "https://223.5.5.5/dns-query";
          }
        ];
      }
    else
      {
        concurrent = 2;
        socks5 = cfg.remoteSocks5;
        upstreams = [
          {
            tag = "google_doh";
            addr = "https://dns.google/dns-query";
          }
          {
            tag = "cf_doh";
            addr = "https://dns.cloudflare.com/dns-query";
          }
        ];
      };

  mosdnsConfig = lib.generators.toYAML { } {
    log.level = "info";
    plugins = [
      {
        tag = "cn_domain";
        type = "domain_set";
        args.files = [ "${rulesDir}/direct-list.txt" ];
      }
      {
        tag = "proxy_domain";
        type = "domain_set";
        args.files = [ "${rulesDir}/proxy-list.txt" ];
      }
      {
        tag = "cn_ip";
        type = "ip_set";
        args.files = [
          "${rulesDir}/china-ip.txt"
          "${rulesDir}/china-ipv6.txt"
        ];
      }

      {
        tag = "china_forward";
        type = "forward";
        args = {
          concurrent = 2;
          upstreams = [
            {
              tag = "ali";
              addr = "udp://223.5.5.5";
            }
            {
              tag = "dnspod";
              addr = "udp://119.29.29.29";
            }
          ];
        };
      }
      {
        tag = "remote_forward";
        type = "forward";
        args = remoteForwardArgs;
      }

      {
        tag = "cache";
        type = "cache";
        args = {
          size = 8192;
          lazy_cache_ttl = 86400;
          dump_file = "${stateDir}/cache.dump";
          dump_interval = 600;
        };
      }

      {
        tag = "china_seq";
        # prefer_ipv4:雙棧域名壓掉 AAAA;純 v6 域名(沒有 A 記錄)不受影響。
        type = "sequence";
        args = [
          { exec = "prefer_ipv4"; }
          { exec = "$china_forward"; }
        ];
      }
      {
        tag = "remote_seq";
        # 與 china_seq 的 prefer_ipv4 同理。
        type = "sequence";
        args = [
          { exec = "prefer_ipv4"; }
          { exec = "$remote_forward"; }
        ];
      }
      # 問中國上游,答案沒有 CN IP 就丟棄;空回應觸發 fallback 的第二路 (遠端)。
      {
        tag = "china_verify_seq";
        type = "sequence";
        args = [
          { exec = "prefer_ipv4"; }
          { exec = "$china_forward"; }
          {
            matches = [ "!resp_ip $cn_ip" ];
            exec = "drop_resp";
          }
        ];
      }
      {
        tag = "split_fallback";
        type = "fallback";
        args = {
          primary = "china_verify_seq";
          secondary = "remote_seq";
          always_standby = false;
        };
      }

      {
        tag = "main";
        type = "sequence";
        args = [
          { exec = "$cache"; }
          {
            matches = [ "has_resp" ];
            exec = "accept";
          }
          {
            matches = [ "qname $cn_domain" ];
            exec = "goto china_seq";
          }
          {
            matches = [ "qname $proxy_domain" ];
            exec = "goto remote_seq";
          }
          { exec = "$split_fallback"; }
        ];
      }

      {
        tag = "udp_server";
        type = "udp_server";
        args = {
          entry = "main";
          listen = "127.0.0.1:${toString cfg.port}";
        };
      }
      {
        tag = "tcp_server";
        type = "tcp_server";
        args = {
          entry = "main";
          listen = "127.0.0.1:${toString cfg.port}";
        };
      }
    ];
  };
in
{
  options.services'.mosdns = {
    enable = lib.mkEnableOption "mosdns DNS forwarder with China/foreign split";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5335;
      description = "Loopback UDP/TCP port mosdns listens on.";
    };

    remoteSocks5 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.2.1:7890";
      description = ''
        `host:port` of a SOCKS5 proxy for the foreign DoH upstreams
        (`dns.google`, `dns.cloudflare.com`). The proxy resolves those
        names. Null keeps direct AliDNS DoH, which does not leave China.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.mosdns = { };
    users.users.mosdns = {
      isSystemUser = true;
      group = "mosdns";
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 mosdns mosdns -"
      "d ${rulesDir} 0755 mosdns mosdns -"
    ];

    systemd.services.mosdns = {
      description = "mosdns DNS forwarder";
      documentation = [ "https://irine-sistiana.gitbook.io/mosdns-wiki/" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "mosdns";
        Group = "mosdns";
        ExecStartPre = "+${ensureRules}";
        ExecStart = "${lib.getExe pkgs.mosdns} start -c ${pkgs.writeText "mosdns-config.yaml" mosdnsConfig}";
        Restart = "on-failure";
        RestartSec = "5s";
        CapabilityBoundingSet = [ "" ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ stateDir ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
      };
    };

    systemd.services.mosdns-rules-update = {
      description = "Update mosdns rule files (geosite/geoip)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = updateRules;
      };
    };

    systemd.timers.mosdns-rules-update = {
      description = "Daily refresh of mosdns rule files";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "24h";
        RandomizedDelaySec = "30min";
        Persistent = true;
      };
    };

    assertions = [
      {
        assertion = cfg.remoteSocks5 == null || lib.match ".*:[0-9]+" cfg.remoteSocks5 != null;
        message = "services'.mosdns.remoteSocks5 must be host:port";
      }
    ];

    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = stateDir;
        user = "mosdns";
        group = "mosdns";
        mode = "0755";
      }
    ];
  };
}
