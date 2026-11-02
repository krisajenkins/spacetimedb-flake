{
  description = "SpacetimeDB CLI and standalone server, packaged from upstream's prebuilt releases";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      inherit ((lib.importJSON ./sources.json)) version platforms;

      forAllSystems =
        f:
        lib.genAttrs (builtins.attrNames platforms) (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
              # BSL-1.1 is unfree in nixpkgs' terms. Allow just this package, so
              # `nix build`/`nix run` on this flake work without NIXPKGS_ALLOW_UNFREE.
              config.allowUnfreePredicate = pkg: lib.getName pkg == "spacetime";
            }
          )
        );
    in
    {
      # Builds against the consumer's own nixpkgs, so libraries match theirs.
      overlays.default = final: prev: {
        spacetimedb = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (pkgs: {
        default = pkgs.spacetimedb;
        inherit (pkgs) spacetimedb;
      });

      checks = forAllSystems (pkgs: {
        # Proves the binary actually runs here (on Linux, that autoPatchelf found
        # everything) and that it is the version sources.json claims.
        version = pkgs.runCommand "spacetime-version-check" { } ''
          export HOME=$TMPDIR
          ${lib.getExe pkgs.spacetimedb} --version | tee version.txt
          grep -qF ${lib.escapeShellArg version} version.txt
          touch $out
        '';
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.curl
            pkgs.jq
            pkgs.nixfmt
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
