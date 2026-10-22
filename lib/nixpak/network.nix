{
  etc.sslCertificates.enable = true;

  bubblewrap = {
    network = true;
    bind.ro = [
      "/etc/resolv.conf"
      "/etc/hosts"
    ];
  };
}
