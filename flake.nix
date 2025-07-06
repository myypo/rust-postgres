{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      forEachSupportedSystem =
        let
          supportedSystems = [
            "x86_64-linux"
          ];
        in
        (
          f:
          inputs.nixpkgs.lib.genAttrs supportedSystems (
            system:
            f {
              pkgs =
                let
                  overlays = [ inputs.fenix.overlays.default ];
                in
                import inputs.nixpkgs {
                  inherit overlays system;
                };
            }
          )
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell.override { stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.stdenv; } {
            env = {
              LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ pkgs.openssl ]}";
            };

            packages = with pkgs; [
              openssl
              pkg-config

              rust-analyzer-nightly
              (
                with fenix;
                with complete;
                combine [
                  cargo
                  clippy
                  rust-src
                  rustc
                  rustfmt
                  llvm-tools-preview
                ]
              )
            ];
          };
        }
      );
    };
}
