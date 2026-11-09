# spacetimedb-flake (moved)

This flake now lives at
[krisajenkins/spacetimedb-nix](https://github.com/krisajenkins/spacetimedb-nix),
which has the same code and is still being updated. This repo is archived and
will stay on SpacetimeDB 2.14.1.

Change your flake input to:

```nix
spacetimedb.url = "github:krisajenkins/spacetimedb-nix";
```

then run `nix flake update spacetimedb`. Note that the package's `pname` is
`spacetimedb` there (it was `spacetime` here), so update any
`allowUnfreePredicate` that matches on the name.
