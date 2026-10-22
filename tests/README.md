# 測試

`just check` 會執行這裡的 eval 測試：求值每臺主機的設定並與預期值比對，不建置、也不啟用系統。

```text
tests/
├── default.nix    # 執行器:每個案例套用到每一臺主機,失敗時在求值階段報錯
└── security.nix   # 安全設定的案例與清單
```

單獨執行：

```bash
nix build --no-link .#checks.x86_64-linux.eval-tests
```

## 案例怎麼寫

每個案例是一個函式，接收一臺主機的 `nixosSystem` 結果，回傳 `expr`（實際值）與 `expected`（預期值）：

```nix
nix-trust =
  { config, ... }:
  {
    expr = config.nix.settings.trusted-users;
    expected = [ "root" ];
  };
```

- 案例會套用到每一臺主機，新增主機時自動涵蓋。只對部分主機有意義的設定，用
  `lib.optionalAttrs` 讓實際值與預期值同時變成空集合。
- 預期值寫成具體的值，或只依主機宣告的意圖推導（例如 `services'.openssh.rootLogin`），
  不要照抄被測模組的實作，否則模組寫錯時測試也會跟著錯。
- 失敗訊息會列出主機、案例名稱、預期值與實際值。

## 清單

`security.nix` 開頭的清單記錄安全決定，改動它們就是做一次決定，應在同一個變更裡說明理由：

- `openPorts`：各主機對外開放的連接埠。服務新開了埠，或新增主機，都要在這裡登記。
- `caches`：信任的二進位快取與簽章金鑰。每一個都能把任意 store 路徑送進系統。
- `privateDirs`、`privateFiles`、`privateSystemDirs`：有持久化就必須只限本人讀取的路徑。
