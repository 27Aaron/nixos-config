{
  lib,
  vars,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ "user'" ] [ "users" "users" vars.username ])
    (lib.mkAliasOptionModule [ "hm'" ] [ "home-manager" "users" vars.username ])
  ];
}
