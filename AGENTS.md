# Agent Instructions

This repository is a Nix flake for NixOS and nix-darwin hosts. Keep the configuration declarative, composable, and easy to validate before deployment.

## Repository layout

```text
flake.nix
flake.lock

hosts/
├── nixos/
│   ├── common/
│   └── <hostname>/
└── darwin/
    ├── common/
    └── <hostname>/

lib/
└── hosts.nix                 # host discovery helper

vars/
└── default.nix               # shared non-secret user values

profiles/
├── nixos/
│   ├── server.nix
│   └── desktop.nix
└── darwin/
    └── default.nix

modules/
├── nixos/
├── darwin/
└── home/
    ├── common/
    ├── darwin/
    └── nixos/
```

- `hosts/` contains host entry points and host-specific configuration.
- `hosts/nixos/<hostname>/` contains each NixOS host. Servers and workstations share the same layout; express role differences through profiles.
- `hosts/nixos/common/` and `hosts/darwin/common/` contain platform-wide configuration. They are not hosts themselves.
- `profiles/` composes reusable roles such as server and platform defaults.
- `modules/` contains reusable feature modules. Home Manager is embedded in the NixOS and nix-darwin configurations, so shared Home Manager modules belong under `modules/home/common/` and platform-specific modules belong under `modules/home/<platform>/`.
- `modules/home/darwin/` contains Home Manager modules that depend on nix-darwin options or macOS applications, such as Karabiner and nh.
- `lib/` contains the host discovery helper used by the Flake.
- `vars/` contains shared non-secret user values. Keep credentials and other secrets in the separate private repository.
- Do not add `production`, `staging`, or `lab` directory layers until those environments require different behavior. Host metadata can be added later without changing the layout.
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

- A host directory must contain a `default.nix` entry point returning a host module, or a list of modules.
- Declare the host platform with `nixpkgs.hostPlatform` inside the host module; the Flake does not pass a `system` argument.
- The directory name is the host name exposed as `nixosConfigurations.<hostname>` or `darwinConfigurations.<hostname>`.
- Discovery must ignore `common/`, `profiles/`, `lib/`, and other non-host directories.
- When adding a host, create its directory and entry point, import the appropriate profile, and let the discovery code expose it. Do not add a duplicate hand-written Flake entry.

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
