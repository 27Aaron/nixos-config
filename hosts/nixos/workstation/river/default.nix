{
  system = "x86_64-linux";

  modules = [
    (
      {
        config,
        nixosHardware,
        pkgs,
        username,
        ...
      }:
      {
        imports = [
          nixosHardware.nixosModules.apple-t2
          ../../../../profiles/nixos/desktop.nix
          ../../../../modules/nixos/hardware/disko.nix
          ../../../../modules/nixos/hardware/persistence.nix
          ../../../../modules/nixos/hardware/boot/grub.nix
          ../../../../modules/nixos/hardware/boot/systemd-boot.nix
          ./hardware.nix
        ];

        # Temporary GCC 16 build workarounds for terminal packages pulled in
        # by enableAllTerminfo. Remove once the upstream fixes land in a
        # nixpkgs update:
        # - rxvt-unicode: NixOS/nixpkgs#568978
        # - contour/libunicode: NixOS/nixpkgs#569719 (0.7.0 fixes the build)
        nixpkgs.overlays = [
          (final: prev: {
            rxvt-unicode-unwrapped = prev.rxvt-unicode-unwrapped.override {
              stdenv = final.gcc15Stdenv;
            };
            libunicode = prev.libunicode.overrideAttrs (_old: rec {
              version = "0.9.3";
              src = final.fetchFromGitHub {
                owner = "contour-terminal";
                repo = "libunicode";
                tag = "v${version}";
                hash = "sha256-teyo4KYVdS6+WIjOdS5p7fXZJoMQsL7lPugoaAQ07r4=";
              };
              patches = [ ];
            });
            contour = prev.contour.overrideAttrs (_old: rec {
              version = "0.7.0.8982";
              src = final.fetchFromGitHub {
                owner = "contour-terminal";
                repo = "contour";
                tag = "v${version}";
                hash = "sha256-sY3qNaYsoYY6Ox5W7F2WHFHId89WbeGJ4fWs2PFQmNk=";
              };
            });
          })
        ];

        # Temporarily disabled: the GCC 16 transition in nixpkgs currently
        # breaks several terminal packages in enableAllTerminfo. Re-enable,
        # and drop the workaround overlay above, once a nixpkgs update has
        # all the upstream fixes.
        environment.enableAllTerminfo = false;

        time.timeZone = "Asia/Tokyo";

        preservation.preserveAt."/persistent".directories = [
          {
            # preservation auto-generates a matching rule for this path from
            # users.users.<name>.{homeMode,group}; reference the same values
            # here so the two definitions don't conflict.
            directory = "/home/${username}";
            user = username;
            group = config.users.users.${username}.group;
            mode = config.users.users.${username}.homeMode;
          }
        ];

        environment.systemPackages = with pkgs; [
          git
          vim
        ];

        system.stateVersion = "26.05";
      }
    )
  ];
}
