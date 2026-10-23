{
  lib,
  pkgs,
  nixosConfigurations,
  darwinConfigurations,
}:
let
  cases = lib.genAttrs [ "shared" "nixos" "darwin" ] (
    platform: import ./security/${platform}.nix { inherit lib; }
  );

  # 每個案例套用到該平臺的每一臺主機;runTests 只執行名稱以 test 開頭的項目。
  testsFor =
    platformCases:
    lib.concatMapAttrs (
      hostName: host:
      lib.mapAttrs' (name: case: lib.nameValuePair "test ${hostName} ${name}" (case host)) platformCases
    );

  tests =
    testsFor (cases.shared // cases.nixos) nixosConfigurations
    // testsFor (cases.shared // cases.darwin) darwinConfigurations;

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
