{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.mime-apps;

  browser = [
    "google-chrome.desktop"
    "firefox.desktop"
  ];
  editor = [
    "dev.zed.Zed.desktop"
    "code.desktop"
  ];
in
{
  options.gui.mime-apps.enable = lib.mkEnableOption "default applications for MIME types";

  config = lib.mkIf cfg.enable {
    # 只列已安裝的程式。
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = browser;
        "text/xml" = browser;
        "application/xml" = browser;
        "application/xhtml+xml" = browser;
        "application/xhtml_xml" = browser;
        "application/rdf+xml" = browser;
        "application/rss+xml" = browser;
        "application/pdf" = browser;
        "application/x-extension-htm" = browser;
        "application/x-extension-html" = browser;
        "application/x-extension-shtml" = browser;
        "application/x-extension-xht" = browser;
        "application/x-extension-xhtml" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/ftp" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;

        "text/plain" = editor;
        "application/json" = editor;
        "x-scheme-handler/vscode" = [ "code-url-handler.desktop" ];

        "x-scheme-handler/tg" = [ "xyz.nextalone.nagram.desktop.desktop" ];

        # 目錄用 Nautilus,由 desktop'.file-manager 安裝。
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      };
    };

    home.packages = [ pkgs.xdg-utils ];
  };
}
