# SpacetimeDB CLI and standalone server, from upstream's prebuilt release
# tarballs. Nothing is compiled here: the version and per-platform hashes live
# in sources.json, which ./update.sh rewrites.
#
# Each tarball holds two binaries at its root:
#   - spacetimedb-cli         (installed as `spacetime`)
#   - spacetimedb-standalone
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
}:

let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;
  inherit (stdenv.hostPlatform) system isLinux;

  # Upstream also ships x86_64-pc-windows-msvc, which Nix has no use for.
  source =
    sources.platforms.${system}
      or (throw "spacetimedb: upstream publishes no build for ${system} (have: ${lib.concatStringsSep ", " (builtins.attrNames sources.platforms)})");
in
stdenv.mkDerivation {
  pname = "spacetime";
  inherit version;

  src = fetchurl {
    url = "https://github.com/clockworklabs/SpacetimeDB/releases/download/v${version}/spacetime-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  # The Linux tarballs are ordinary dynamically-linked ELF executables built
  # against a distro glibc: they ask for the interpreter at /lib64/ld-linux-*.so,
  # which doesn't exist on a Nix-managed system. autoPatchelfHook rewrites the
  # interpreter and RPATH to point into the store. The Mach-O binaries need no
  # equivalent fixup.
  nativeBuildInputs = lib.optional isLinux autoPatchelfHook;

  buildInputs = lib.optionals isLinux [
    zlib # libz.so.1 (spacetimedb-cli, x86_64 only)
    stdenv.cc.cc.lib # libgcc_s.so.1, libstdc++.so.6
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 spacetimedb-cli $out/bin/spacetime
    install -Dm755 spacetimedb-standalone $out/bin/spacetimedb-standalone
    runHook postInstall
  '';

  meta = {
    description = "SpacetimeDB CLI and standalone server";
    homepage = "https://spacetimedb.com";
    changelog = "https://github.com/clockworklabs/SpacetimeDB/releases/tag/v${version}";
    # Business Source License 1.1, converting to AGPL-3.0 on 2030-10-31.
    # nixpkgs classes it as unfree.
    license = lib.licenses.bsl11;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames sources.platforms;
    mainProgram = "spacetime";
  };
}
