{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  # 只有 1 GB 記憶體,同時建置多個套件會耗盡。
  nix.settings.max-jobs = 1;

  # 記憶體小,不保留預設 256M 的記憶體內日誌。
  core'.logging = {
    journalMaxUse = "128M";
    journalRuntimeMaxUse = "16M";
  };

  services' = {
    openssh = {
      enable = true;
      rootLogin = true;
    };
    vnstat.enable = true;
    zram.enable = true;
  };

  server'.fail2ban.enable = true;

  system.stateVersion = "26.05";
}
