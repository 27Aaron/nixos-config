# Default host is the machine's own hostname.
host := env("HOST", `hostname -s`)

# List available recipes.
default:
    @just --list

# Format all Nix files.
fmt:
    @nix fmt .

# Check dead code, evaluate every host, and fail if formatting is off.
# Note: treefmt has no read-only mode, so it reformats files in place first.
check:
    @nix fmt . -- --fail-on-change
    @deadnix --fail .
    @nix flake check --no-build --all-systems

# Build a host configuration without activating it.
[macos]
build target=host:
    @darwin-rebuild build --flake .#{{target}}

[linux]
build target=host:
    @nixos-rebuild build --flake .#{{target}}

# Build and activate a host configuration.
[macos]
switch target=host:
    @nh darwin switch path:. -H {{target}}

[linux]
switch target=host:
    @nh os switch path:. -H {{target}}

# Deploy a remote NixOS host, building locally.
[linux]
deploy target remote:
    @nixos-rebuild switch --flake .#{{target}} --target-host {{remote}}

# Update all flake inputs.
update:
    @nix flake update

# Update a single flake input.
update-input input:
    @nix flake update {{input}}

# Clean old generations and unreachable store paths.
gc:
    @nh clean all --keep 8 --keep-since 14d --ask

# Install nix-darwin on a fresh macOS host.
[macos]
install target=host:
    @sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake path:.#{{target}}
