{
  # Compose platform and Home Manager modules for every Darwin host.
  imports = [
    ../../modules/darwin
    ../../modules/home
    ../../modules/home/darwin
  ];
}
