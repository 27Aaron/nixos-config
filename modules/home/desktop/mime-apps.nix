{ pkgs, ... }:
let
  browser = [
    "google-chrome.desktop"
    "firefox.desktop"
  ];
  editor = [ "code.desktop" ];
in
{
  # 只列出已安裝的程式;播放器、圖片檢視與解壓縮尚未安裝,不在這裡指定。
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # 瀏覽器,Chrome 優先。
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

      # 文字檔用 VS Code。
      "text/plain" = editor;
      "application/json" = editor;
      "x-scheme-handler/vscode" = [ "code-url-handler.desktop" ];

      # Telegram 連結。
      "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];

      # 目錄用 Nautilus,由 niri 的入口帶入。
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };

  # xdg-open 等工具,mimeApps 生成的關聯靠它生效。
  home.packages = [ pkgs.xdg-utils ];
}
