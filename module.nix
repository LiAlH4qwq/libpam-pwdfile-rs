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
                    example = "$y$j9T$F5Jx5fExrKuPp53xLKQ..1$X3DX6M94c7o.9agCG9G317fhZg9SqC.5i5rd.RhvU7D";
                    description = "Password hashed with yescrypt (use: mkpasswd -m yescrypt)";
                  };
                };
              }
            );
            default = { };
            example = {
              lialh4.secret = "$y$j9T$F5Jx5fExrKuPp53xLKQ..1$X3DX6M94c7o.9agCG9G317fhZg9SqC.5i5rd.RhvU7D";
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
                printf '%s\n' '${n}:${v.secret}' >> ${val.pwdfile}
              '') val.users
            )}
          '';
          deps = [ ];
        };
      }
    ) config.libpam-pwdfile-rs
  );
}
