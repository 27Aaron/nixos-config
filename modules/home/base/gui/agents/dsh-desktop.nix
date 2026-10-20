# dsh-desktop:dsh 的 Electron 前端,開自己的視窗。
{
  inputs,
  pkgs,
  ...
}:
let
  nur = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [ nur.dsh-desktop ];

  # Electron 設定與崩潰紀錄。
  persist'.directories = [ ".config/@deepseek-ai/dsh-desktop" ];
}
