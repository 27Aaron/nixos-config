{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.firefox ];

  # Firefox 把「要保留的」與「可重建的」放在不同位置,因此這裡的拆分很乾淨:
  # 使用者資料全在 .config/mozilla,快取全在 .cache/mozilla。
  #
  # 憑證庫不需要另外登記:Firefox 用自己 profile 內的 cert9.db 與 key4.db,
  # 不碰 Chrome 系的 ~/.pki。
  persist'.directories = [
    # profile 目錄:書籤與歷史(places.sqlite)、已安裝擴充功能、
    # 憑證與登入資訊(cert9.db/key4.db/logins.json)、網站資料(storage/
    # 底下的 LocalStorage 與 IndexedDB),以及各項偏好。
    #
    # storage/ 佔了 profile 的一半以上,但它不是快取:那是各網站的
    # 登入態與離線資料,丟掉等同所有網站登出。因此整個 profile 保留,
    # 不逐項細拆——這些資料庫彼此關聯,拆開容易漏。
    ".config/mozilla"

    # HTTP 快取。保留它是為了不佔用記憶體而非保留資料:根目錄是 4G 的
    # tmpfs,而這個目錄實測可長到 1G 以上。內容可重建,過期由 Firefox
    # 自己的淘汰機制處理。
    {
      directory = ".cache/mozilla";
      mode = "0700";
    }
  ];
}
