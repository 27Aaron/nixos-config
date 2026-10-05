# Turns inventory entries into nixosConfigurations / darwinConfigurations.
#
# A host only provides data; the defaults that are the same for every machine
# (host platform, state version, effective time zone, Home Manager wiring) are
# applied here. Profile names are resolved against profiles/ here as well, so a
# host file never imports anything and needs no arguments.
{
  lib,
  vars,
  profiles,
  hosts,
  inputs,
}:
let
  flatten = builtins.concatLists;

  resolve =
    axis: names:
    map (
      name:
      if axis ? ${name} then
        axis.${name}
      else
        throw "unknown profile \"${name}\"; available: ${lib.concatStringsSep ", " (lib.attrNames axis)}"
    ) names;

  # The host must name at least one profile for its own platform.
  platformProfiles =
    host:
    let
      names = host.profiles.${host.platform};
    in
    if names == [ ] then
      throw "host ${host.name}: profiles.${host.platform} is empty; name the roles the host plays"
    else
      flatten (resolve profiles.${host.platform} names);

  homeProfiles = host: flatten (resolve profiles.home host.profiles.home);

  # Shared values first, then the per-host overrides on top of them.
  hostArgs =
    host:
    vars
    // {
      hostName = host.name;
      inherit host profiles;
      timeZone = if host.timeZone != null then host.timeZone else vars.timeZone;
    };

  hostDefaults = host: {
    nixpkgs.hostPlatform = lib.mkDefault host.system;
    system.stateVersion = lib.mkDefault host.stateVersion;
  };

  homeManager = host: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-bak";
      extraSpecialArgs = hostArgs host;
      users.${vars.username}.imports = homeProfiles host ++ [ ../modules/home/base.nix ];
    };
  };

  mkNixos =
    host:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = hostArgs host // {
        inherit (inputs) disko preservation;
        nixosHardware = inputs.nixos-hardware;
      };
      # The platform's Home Manager module stays first, and the platform modules
      # reach the system through a single module's `imports`, so the collection
      # order — and with it the order of packages in the system profile — matches
      # the hand-written configurations this replaced.
      modules = [
        inputs.home-manager.nixosModules.home-manager
        { imports = platformProfiles host ++ host.modules; }
        ../modules/home
        (hostDefaults host)
        (homeManager host)
      ];
    };

  mkDarwin =
    host:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = hostArgs host;
      # Same shape as mkNixos: one module carrying the host's own modules.
      modules = [
        inputs.home-manager.darwinModules.home-manager
        { imports = platformProfiles host ++ host.modules; }
        ../modules/home
        (hostDefaults host)
        (homeManager host)
      ];
    };

  byPlatform = platform: lib.filterAttrs (_: host: host.platform == platform);
in
{
  nixosConfigurations = lib.mapAttrs (_: mkNixos) (byPlatform "nixos" hosts);
  darwinConfigurations = lib.mapAttrs (_: mkDarwin) (byPlatform "darwin" hosts);
}
