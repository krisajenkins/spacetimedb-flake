# spacetimedb-flake

A Nix flake for the [SpacetimeDB](https://spacetimedb.com) CLI (`spacetime`)
and standalone server (`spacetimedb-standalone`).

It packages upstream's prebuilt release binaries, so it installs in seconds
rather than compiling the SpacetimeDB workspace. Each tag here matches an
upstream release: `v2.14.0` gives you SpacetimeDB 2.14.0.

Supported systems: `aarch64-darwin`, `x86_64-darwin`, `aarch64-linux`,
`x86_64-linux`.

## Try it

```sh
nix run github:krisajenkins/spacetimedb-flake -- --version
nix run github:krisajenkins/spacetimedb-flake/v2.14.0 -- --version
```

## Use it in a project

Add the flake as an input and put its package in your devShell:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    spacetimedb.url = "github:krisajenkins/spacetimedb-flake";
    # spacetimedb.url = "github:krisajenkins/spacetimedb-flake/v2.14.0";  # pinned
  };

  outputs = { nixpkgs, spacetimedb, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ spacetimedb.packages.${system}.default ];
      };
    };
}
```

Then `nix develop` (or `direnv reload`) and `spacetime` is on your `PATH`.

You don't need an overlay, and you don't need `allowUnfree`. This flake
builds the package and accepts SpacetimeDB's licence for that one package
itself (see [Licence](#licence)).

Optionally, add `spacetimedb.inputs.nixpkgs.follows = "nixpkgs";` to skip
fetching a second copy of nixpkgs. Upstream ships prebuilt binaries, so which
nixpkgs they're linked against makes no practical difference.

### As an overlay

If you'd rather have it as `pkgs.spacetimedb`, replacing nixpkgs' own
from-source package (which usually lags behind releases), use the overlay.
Because the package is then built by *your* nixpkgs, you have to accept the
licence yourself:

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ spacetimedb.overlays.default ];
  config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "spacetime";
};
```

### Upgrading

If you're tracking the latest version:

```sh
nix flake update spacetimedb
```

If you're pinned to a version, edit the tag in the input URL and run the same
command.

## Licence

SpacetimeDB is under the Business Source License 1.1, which nixpkgs counts as
unfree. This flake's `packages` allow it for you. If you use the overlay
instead, your own nixpkgs config has to allow it, either with `allowUnfree` or
with an `allowUnfreePredicate` that admits `spacetime`.

The packaging in this repo is MIT-licensed.

## Maintenance

A scheduled GitHub Action (`.github/workflows/update.yml`) checks daily for a
new upstream release. When it finds one, it re-hashes the tarballs, checks the
binary runs, commits to `main` and pushes a matching `vX.Y.Z` tag. To run it
now, use **Actions → Update → Run workflow**, optionally with a version.

To update by hand:

```sh
nix develop -c ./update.sh            # latest release
nix develop -c ./update.sh 2.15.0     # specific version
nix flake check -L
jj commit -m "Update SpacetimeDB to v2.15.0"
jj tag set v2.15.0 -r @-
jj bookmark set main -r @-
jj git push --bookmark main --tag v2.15.0
```

Tags only ever follow upstream versions. A packaging fix with no upstream
release goes to `main` and gets picked up by `nix flake update`. Existing tags
stay where they are.
