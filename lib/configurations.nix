# Turns inventory entries into nixosConfigurations / darwinConfigurations.
#
# A host only provides data; the defaults that are the same for every machine
# (host platform, state version, effective time zone, Home Manager wiring) are
# applied here.
{
  lib,
  vars,
  profiles,
  hosts,
  inputs,
}:
let
  flatten = builtins.concatLists;

  # The host must name at least one profile for its own platform.
  platformProfiles =
    host:
    let
      selected = host.profiles.${host.platform};
    in
    if selected == [ ] then
      throw "host ${host.name}: profiles.${host.platform} is empty; name the roles the host plays"
    else
      flatten selected;

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
      users.${vars.username}.imports = flatten host.profiles.home ++ [ ../modules/home/base.nix ];
    };
  };

  mkNixos =
    host:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = hostArgs host // {
        inherit (inputs) disko preservation;
        nixosHardware = inputs.nixos-hardware;
      };
      # The platform's Home Manager module stays first, like the hand-written
      # configurations used to.
      modules = [
        inputs.home-manager.nixosModules.home-manager
      ]
      ++ platformProfiles host
      ++ host.modules
      ++ [
        ../modules/home
        (hostDefaults host)
        (homeManager host)
      ];
    };

  mkDarwin =
    host:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = hostArgs host;
      modules = [
        inputs.home-manager.darwinModules.home-manager
      ]
      ++ platformProfiles host
      ++ host.modules
      ++ [
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
