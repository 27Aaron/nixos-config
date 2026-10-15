# 預設主機為本機的主機名稱。
host := env("HOST", `hostname -s`)

# 列出所有可用的配方。
default:
    @just --list

# 格式化所有 Nix 檔案。
fmt:
    @nix fmt .

# 檢查格式與死碼,並求值所有主機。
check:
    @nix fmt . -- --check
    @deadnix --fail .
    @nix flake check --no-build --all-systems

# 建置主機設定,不啟用。
build target=host:
    @nixos-rebuild build --flake .#{{target}}

# 建置並啟用主機設定。
switch target=host:
    @nh os switch path:. -H {{target}}

# 部署遠端 NixOS 主機,於本機建置。
deploy target remote:
    @nixos-rebuild switch --flake .#{{target}} --target-host {{remote}}

# 更新所有 flake 輸入。
update:
    @nix flake update

# 更新單一 flake 輸入。
update-input input:
    @nix flake update {{input}}

# 清理舊的 generations 與不再被引用的 store 路徑。
gc:
    @nh clean all --keep 8 --keep-since 14d --ask
