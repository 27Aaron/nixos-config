# 主要使用者的選項別名。
{ lib, vars, ... }:
{
  imports = [
    (lib.mkAliasOptionModule [ "user'" ] [ "users" "users" vars.username ])
    (lib.mkAliasOptionModule [ "hm'" ] [ "home-manager" "users" vars.username ])
  ];
}
