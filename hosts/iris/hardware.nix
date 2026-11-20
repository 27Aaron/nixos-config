{
  hardware'.kvm-guest = {
    enable = true;
    diskDevice = "/dev/sda";
  };

  hardware'.clevis.enable = true;
}
