# Loads the shared values and the host data files, and exposes the result as the
# typed `hosts` option declared in host-options.nix.
{ lib, ... }:
let
  profiles = import ../profiles;
  vars = import ../vars;

  hosts = import ../lib/hosts.nix { inherit lib profiles vars; };
in
{
  # Take the supported systems from the hosts themselves, so per-system outputs
  # follow the inventory instead of a second hand-written list.
  systems = lib.unique (map (host: host.system) (lib.attrValues hosts));

  _module.args = { inherit profiles vars; };

  inherit hosts;
}
