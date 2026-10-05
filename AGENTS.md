# Agent Instructions

This repository is a Nix flake for NixOS and nix-darwin hosts. Keep the configuration declarative, composable, and easy to validate before deployment.

## Repository layout

```text
flake.nix
flake.lock

parts/                        # flake-parts modules
├── default.nix               # what the Flake is made of
├── host-options.nix          # schema for the host data files
├── inventory.nix             # loads hosts, derives the supported systems
├── configurations.nix        # contributes the systems to the Flake outputs
└── dev.nix                   # formatter and development shell (treefmt-nix)

hosts/
├── nixos/
│   └── <name>/               # host data, plus host-local modules
└── darwin/
    └── <name>/

lib/
├── hosts.nix                 # host inventory: discovery and validation
└── configurations.nix        # turns inventory entries into configurations

vars/
└── default.nix               # shared non-secret user values

profiles/
├── default.nix               # re-exports the profile sets below
├── nixos/default.nix         # named role compositions for NixOS
├── darwin/default.nix        # named role compositions for nix-darwin
└── home/default.nix          # named Home Manager module sets

modules/
├── nixos/
├── darwin/
└── home/
    ├── base.nix              # baseline Home Manager user configuration
    ├── common/               # Home Manager modules shared by both platforms
    └── darwin/               # Home Manager modules that need nix-darwin or macOS
```

- `hosts/` contains one entry per machine: a data file describing the host, plus any modules specific to it.
- The Flake is assembled with flake-parts, which turns it into a module system; `parts/` holds those modules. `parts/host-options.nix` declares the schema for host data, `parts/inventory.nix` loads the hosts and derives the supported systems, `parts/configurations.nix` contributes the systems to the Flake outputs, and `parts/dev.nix` provides the formatter and dev shell.
- `hosts/<platform>/<name>/default.nix` is **data, not a module**. It must define `system`, `stateVersion` and `profiles`; it may also define `timeZone`, `modules`, `hardware` and `homeStateVersion`. The allowed fields, and the profile axes, are declared in `parts/host-options.nix`. The platform is taken from the directory it lives in.
- `lib/hosts.nix` is the inventory: it loads and validates every host. `lib/configurations.nix` assembles the systems and applies the shared defaults (host platform, state version, effective time zone, Home Manager wiring), so a host only states what makes it different.
- `profiles/<platform>/default.nix` maps a role name to a list of modules. Profiles may extend each other, so a host only names the roles it plays.
- `profiles/home/default.nix` maps a name to Home Manager user modules; a host selects those under its `profiles.home` axis.
- `modules/` contains reusable feature modules. Home Manager is embedded in the NixOS and nix-darwin configurations, so shared Home Manager modules belong under `modules/home/common/` and platform-specific modules belong under `modules/home/<platform>/`.
- `modules/home/darwin/` contains Home Manager modules that depend on nix-darwin options or macOS applications, such as Karabiner and nh.
- `lib/` contains the host inventory and the code that builds configurations from it.
- `vars/` contains shared non-secret user values. Keep credentials and other secrets in the separate private repository.
- Group machines with profiles rather than directory layers. Do not add `production`, `staging`, or `lab` directories until those environments require different behavior.
- Darwin currently targets `aarch64-darwin`; do not create architecture-specific directories or files for unsupported Darwin systems.

## Configuration boundaries

- Put hardware, boot, filesystems, networking, and other machine-specific settings in the host directory.
- Put role composition in `profiles/`; profiles should not contain values tied to one host.
- Put one reusable capability in each module under `modules/`.
- Optional features should expose an `enable` option using `lib.mkEnableOption` or an equivalent typed option.
- Prefer shared modules and profiles over copying the same settings into multiple hosts.
- Keep platform-specific Home Manager modules under `modules/home/<platform>/`; shared modules belong under `modules/home/common/`.

## Host discovery

The Flake discovers hosts from the directory tree instead of maintaining a second manual host list.

- Every directory under `hosts/<platform>/` is a host. The directory name is the host name exposed as `nixosConfigurations.<name>` or `darwinConfigurations.<name>`.
- A host entry point is a data file, called with `{ lib, profiles, vars }`; write it as `{ profiles, ... }:`. It must return `system`, `stateVersion` and `profiles`, and `lib/hosts.nix` rejects a host that leaves one out.
- `profiles` names what the host plays; each axis takes a list of module lists, normally written as `with profiles.nixos; [ server desktop ]`. The host must name at least one profile for its own platform.
- Machine-specific modules, such as `hardware.nix`, are listed in the host's `modules` field.
- The Flake does not pass a `system` argument; the host states its own platform.
- Adding a host means creating `hosts/<platform>/<name>/default.nix` and nothing else — no hand-written Flake entry:

  ```nix
  { profiles, ... }:
  {
    system = "x86_64-linux";
    stateVersion = "26.05";
    timeZone = "Asia/Tokyo";

    profiles = {
      nixos = with profiles.nixos; [ server ];

      home = with profiles.home; [ common ];
    };

    modules = [ ./hardware.nix ];
  }
  ```

## Secrets

Secrets are managed in a separate private repository. Secrets are outside the scope of this repository's refactor.

- Do not create a `secrets/` tree here.
- Do not add secret values, keys, encrypted secret files, or private-repository contents to this repository.
- Keep only non-sensitive integration code here when the private repository is connected later.

## Style and formatting

- Use two spaces for indentation, no tabs, LF line endings, a final newline, and no trailing whitespace.
- Run the repository formatter with `nix fmt` after editing Nix files.
- Format files changed by the task; do not reformat unrelated files.
- Preserve the existing module argument and option naming conventions when extending a module.

## Validation

Run the checks relevant to the change:

```bash
nix fmt
nix flake check
nixos-rebuild build --flake .#<nixos-host>
darwin-rebuild build --flake .#<darwin-host>
```

Build every affected host when changing host discovery, profiles, shared modules, or Flake inputs. A focused module change may use the smallest representative host that exercises it.

## Deployment

Build before switching. Deployment is manual and must be explicitly requested; do not run a switch or remote deployment as a side effect of validation.

```bash
# Local NixOS host
nixos-rebuild switch --flake .#<nixos-host>

# Remote NixOS host
nixos-rebuild switch --flake .#<nixos-host> --target-host <user>@<host>

# Local Darwin host
darwin-rebuild switch --flake .#<darwin-host>
```

## Commit messages

Use Conventional Commit titles with a path-based scope:

```text
type(scope): description
```

- Allowed types are `feat`, `fix`, `refactor`, `chore`, and `WIP`. Use `WIP` only for an explicitly temporary work-in-progress snapshot.
- The commit title uses lowercase English text and never ends with a period. Keep the body readable with normal capitalization when it contains proper names or explanatory sentences.
- The scope reflects the changed path or component. Prefer scopes in this order:
  - `{host}` or `{host}/{service}` for host-specific changes, for example `beelink`, `router/network`, or `vps-01/openssh`.
  - `profile/{role}` for role composition, for example `profile/server`.
  - `nixos/{feature}` or `darwin/{feature}` for shared platform modules, for example `nixos/niri` or `darwin/default`.
  - `home/{feature}` for Home Manager features, for example `home/git` or `home/fish`.
  - `flake` for `flake.nix`, `flake.lock`, host discovery, or Flake inputs.
  - `docs` for repository documentation, including this file.
- Keep the title concise and describe the resulting change, not the list of edited files.

### Flake lock bumps

When updating an input in `flake.lock`, describe the upstream change instead of only mentioning the lock file or revision hashes.

1. Run `nix flake update <input>` and record the old and new revisions from its output or from `git diff -- flake.lock`.
2. Identify the upstream repository and inspect the change range. For a GitHub input, use the compare API or `gh`:

   ```bash
   curl -s https://api.github.com/repos/<owner>/<repo>/compare/<old>...<new>
   # or
   gh api repos/<owner>/<repo>/compare/<old>...<new>
   ```

3. Review the commits or changed files and keep only meaningful changes in the commit body.
4. Use a title naming the input, followed by the short revision range and a brief bullet list:

   ```text
   chore(flake): update home-manager input

   Update home-manager from f6c09b0b to 70386bb7 (2 commits):
   - summarize the meaningful change
   - summarize another relevant file or commit
   ```

For multiple inputs, name all of them in the title or split the updates into separate commits. Do not claim details that are not supported by the upstream changelog or the local diff.
