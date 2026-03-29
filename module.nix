{
  config,
  lib,
  pkgs,
  ...
}:
let
  package = pkgs.callPackage ./package.nix { };
in
{
  options.libpam-pwdfile-rs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          pwdfile = lib.mkOption {
            type = lib.types.path;
            default = /etc/pwdfile;
            example = /etc/pin;
            description = "pwdfile used for auth.";
          };
          services = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "gdm"
              "polkit-1"
            ];
            description = "PAM services to enable for.";
          };
          users = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  secret = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                    example = "7782b56db225e3136eea6379a63b610237fca412cf50b93918e3fc67fa2bede1cc40128e9db58ac68eb4d73103dbfcb8f4b556eed9081824a98b9b11f7498b69";
                    description = "Password hashed by `sha512sum`";
                  };
                };
              }
            );
            default = { };
            example = {
              lialh4 = "9347259d6b1d86cc3a1eb2dd7b5d7a529d2e26524c16307e5f5bd9ca5b7513140f6f12f1c8066ab025d40579d9911e6c5bdbd4a17ba4bd5f6abfffb2947e2141";
            };
            description = "Users and their hashed passwords used for auth.";
          };
        };
      }
    );
    default = { };
    example = {
      pin = {
        pwdfile = /etc/pin;
        services = [
          "gdm"
          "polkit-1"
        ];
      };
    };
    description = "pwdfile instances used to auth.";
  };

  config.security.pam.services = lib.mkMerge (
    lib.mapAttrsToList (
      _: val:
      lib.genAttrs val.services (_: {
        rules.auth.pwdfile = {
          order = 11500;
          control = "sufficient";
          modulePath = "${package}/lib/security/pam_pwdfile_rs.so";
          args = [
            "pwdfile"
            (toString val.pwdfile)
          ];
        };
      })
    ) config.libpam-pwdfile-rs
  );

  config.system.activationScripts = lib.mkMerge (
    lib.mapAttrsToList (
      name: val:
      lib.optionalAttrs (val.users != { }) {
        "libpam-pwdfile-rs-${name}" = {
          text = ''
            install -Dm600 /dev/null ${val.pwdfile}
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (n: v: ''
                echo "${n}:${v.secret}" >> ${val.pwdfile}
              '') val.users
            )}
          '';
          deps = [ ];
        };
      }
    ) config.libpam-pwdfile-rs
  );
}
