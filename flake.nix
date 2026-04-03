{
  description = "libpam-pwdfile-rs - PAM module that auth against pwdfile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      nixosModules = rec {
        default = libpam-pwdfile-rs;
        libpam-pwdfile-rs = import ./module.nix;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./package.nix { };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
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
        }
      );
    };
}
