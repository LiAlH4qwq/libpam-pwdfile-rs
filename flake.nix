{
  description = "libpam-pwdfile-rs - PAM module that auth against pwdfile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = _: {
    nixosModules = rec {
      libpam-pwdfile-rs = import ./module.nix;
      default = libpam-pwdfile-rs;
    };
  };
}
