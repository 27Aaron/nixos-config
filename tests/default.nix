{
  lib,
  pkgs,
  nixosConfigurations,
}:
let
  cases =
    import ./security/shared.nix { inherit lib; } // import ./security/nixos.nix { inherit lib; };

  # 每個案例套用到每一臺主機;runTests 只執行名稱以 test 開頭的項目。
  tests = lib.concatMapAttrs (
    hostName: host:
    lib.mapAttrs' (name: case: lib.nameValuePair "test ${hostName} ${name}" (case host)) cases
  ) nixosConfigurations;

  failures = lib.debug.runTests tests;
in
# just check 以 --no-build 執行 flake check,建置階段才失敗的 check 不會被
# 發現,因此在求值階段就丟出錯誤。
if failures == [ ] then
  pkgs.writeText "eval-tests" (lib.concatLines (lib.attrNames tests))
else
  throw ''
    eval tests failed:
    ${lib.generators.toPretty { } failures}
  ''
