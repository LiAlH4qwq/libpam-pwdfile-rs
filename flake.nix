{
  description = "libpam-pwdfile-rs - PAM module that auth against pwdfile";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake.nixosModules = rec {
        default = libpam-pwdfile-rs;
        libpam-pwdfile-rs = import ./module.nix;
      };

      perSystem =
        { pkgs, ... }:
        {
          packages.default = pkgs.callPackage ./package.nix { };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.cargo
              pkgs.rustc
              pkgs.rustfmt
              pkgs.clippy
              pkgs.rust-analyzer
              pkgs.pkg-config
              pkgs.clang
            ];

            buildInputs = [
              pkgs.pam
            ];

            shellHook = ''
              echo "libpam-pwdfile-rs development environment"
              echo "Rust: $(rustc --version)"
              echo "Cargo: $(cargo --version)"
            '';
          };
        };
    };
}
