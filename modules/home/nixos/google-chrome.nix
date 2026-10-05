{ pkgs, ... }:
{
  home.packages = [ pkgs.google-chrome ];

  persist'.directories = [
    # Google Chrome profiles, extensions, and browser state.
    {
      directory = ".config/google-chrome";
      mode = "0700";
    }
    # Chrome's NSS certificate database: client certificates and imported
    # CAs (private keys live here), shared by NSS-based applications.
    {
      directory = ".pki";
      mode = "0700";
    }
  ];
}
