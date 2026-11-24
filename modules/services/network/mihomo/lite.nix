{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.mihomo-lite;
  inherit (import ./common.nix { inherit lib; })
    testUrl
    base
    rejectRuleProviders
    rejectRules
    directRuleProviders
    directRules
    ;

  foreignDNS = [
    "https://dns.cloudflare.com/dns-query#Proxy"
    "https://dns.google/dns-query#Proxy"
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
      secret = "27Aaron";
    }
    // {
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

      rule-providers = rejectRuleProviders // directRuleProviders;

      # 其餘全部走 Proxy。
      rules = rejectRules ++ directRules ++ [ "MATCH,Proxy" ];
    }
  );

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
    # 與 full.nix 分工:那份用 sops 的訂閱做完整分流;這份種下同一套基礎
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
