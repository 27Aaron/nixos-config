{
  # 短按電源鍵休眠:記憶體寫入加密的 swapfile 後關機,之後可以拔電源。
  # 恢復位置由 systemd 休眠時寫進 EFI 變數 HibernateLocation,initrd 解鎖
  # LUKS 後讀取,因此不必寫死 Btrfs swapfile 的 resume_offset。image_size
  # 由 hardware'.disko 在有 swapfile 時設為 0。
  services.logind.settings.Login.HandlePowerKey = "hibernate";
}
