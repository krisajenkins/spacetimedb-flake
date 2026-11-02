# spacetimedb-nix

A Nix flake for the [SpacetimeDB](https://spacetimedb.com) CLI (`spacetime`)
and standalone server (`spacetimedb-standalone`).

It packages upstream's prebuilt release binaries, so it installs in seconds
rather than compiling the SpacetimeDB workspace. Each tag here matches an
upstream release: `v2.14.0` gives you SpacetimeDB 2.14.0.

Supported systems: `aarch64-darwin`, `x86_64-darwin`, `aarch64-linux`,
`x86_64-linux`.

## Try it

```sh
nix run github:krisajenkins/spacetimedb-nix -- --version
nix run github:krisajenkins/spacetimedb-nix/v2.14.0 -- --version
```

## Use it in a project

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/26.05";
    spacetimedb = {
      url = "github:krisajenkins/spacetimedb-nix";            # latest
      # url = "github:krisajenkins/spacetimedb-nix/v2.14.0";  # pinned
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, spacetimedb, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ spacetimedb.overlays.default ];
        config.allowUnfree = true; # SpacetimeDB is BSL-1.1
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.spacetimedb ];
      };
    };
}
```

The overlay replaces nixpkgs' own `spacetimedb`, which builds from source and
usually lags behind releases.

If you'd rather skip the overlay, use the package directly:
`spacetimedb.packages.${system}.default`. It's built against this flake's
nixpkgs (or yours, with `follows`) and doesn't need `allowUnfree`.

### Upgrading

If you're tracking the latest version:

```sh
nix flake update spacetimedb
```

If you're pinned to a version, edit the tag in the input URL and run the same
command.

## Licence

SpacetimeDB is under the Business Source License 1.1, which nixpkgs counts as
unfree, so consumers of the overlay need `allowUnfree` (or an
`allowUnfreePredicate` that admits `spacetime`).

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
