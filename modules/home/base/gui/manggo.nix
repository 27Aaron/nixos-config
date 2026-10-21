{
  inputs,
  pkgs,
  ...
}:
let
  manggo = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.manggo;
in
{
  home.packages = [ manggo ];

  # 程式自己建立這兩個目錄:設定與翻譯歷史在 .config/Manggo,
  # 使用者資料在 .local/share/Manggo。
  persist' = {
    directories = [
      ".config/Manggo"
      ".local/share/Manggo"
    ];
  };
}
