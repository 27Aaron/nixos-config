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

      # Rusticl 透過 Mesa 提供 OpenCL,支援 Radeon 680M/780M 等
      # GFX9 之後的 iGPU,無需引入龐大許多的 ROCm 套件。
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
  };
}
