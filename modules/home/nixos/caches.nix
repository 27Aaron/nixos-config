# 可重建但隨使用量成長的快取;保留可免去重開機後重新下載、編譯或產生縮圖。
{
  persist'.directories = [
    # Mesa/RADV 的 shader 快取,由驅動自行管理。
    ".cache/mesa_shader_cache"
    ".cache/radv_builtin_shaders"

    # 縮圖可能洩漏私人檔案內容,限本人讀取。
    {
      directory = ".cache/thumbnails";
      mode = "0700";
    }

    # 套件與建置快取:pnpm、Go、Bun。
    ".cache/pnpm"
    ".cache/go-build"
    ".cache/bun"
  ];
}
