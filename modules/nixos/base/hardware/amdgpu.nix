{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.amdgpu;
in
{
  options.hardware'.amdgpu = {
    enable = lib.mkEnableOption "AMD GPU support";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;

      # 以 Rusticl 提供 OpenCL(GFX9 以後),不必引入龐大的 ROCm。
      extraPackages = [ pkgs.mesa.opencl ];
    };

    environment = {
      sessionVariables.RUSTICL_ENABLE = "radeonsi";

      systemPackages = with pkgs; [
        amdgpu_top
        clinfo
        libva-utils
        mesa-demos
        nvtopPackages.amd
        pciutils
        vulkan-tools
      ];
    };

    # Mesa/RADV 的 shader 快取,由驅動自行管理;保留可免去重開機後重新編譯。
    preservation'.user.directories = [
      ".cache/mesa_shader_cache"
      ".cache/radv_builtin_shaders"
    ];
  };
}
