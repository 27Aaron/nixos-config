{
  # 不建置 man page 與 NixOS 手冊,縮短建置時間。
  documentation = {
    man.enable = false;
    nixos.enable = false;
  };
}
