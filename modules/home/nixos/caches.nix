# 可重建但會隨使用量成長的 cache。根目錄是 tmpfs,整目錄保留可避免每次
# 重開機重新下載、編譯或產生縮圖;小型的系統快取仍留在 tmpfs。
{
  persist'.directories = [
    # Mesa/RADV 的 shader cache,由驅動自行管理,跨版本會自行汰換。
    ".cache/mesa_shader_cache"
    ".cache/radv_builtin_shaders"

    # 檔案管理員的圖片/影片縮圖;內容可能反映私人檔案,限制為本人可讀。
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
