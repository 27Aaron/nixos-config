{
  config,
  lib,
  ...
}:
let
  cfg = config.gui'.mangohud;
in
{
  options.gui'.mangohud.enable = lib.mkEnableOption "the MangoHud performance overlay";

  # 不設 enableSessionWide:那會讓每個 Vulkan 程式都顯示疊加層;遊戲改以
  # `mangohud %command%` 個別開啟。
  config = lib.mkIf cfg.enable {
    programs.mangohud = {
      enable = true;
      settings = {
        position = "top-left";
        # 2880x1800 的面板上預設字級太小。
        font_size = 28;
        fps = true;
        frametime = true;
        frame_timing = true;
        gpu_stats = true;
        gpu_temp = true;
        cpu_stats = true;
        cpu_temp = true;
        ram = true;
        vram = true;
        battery = true;
        toggle_hud = "Shift_R+F12";
      };
    };
  };
}
