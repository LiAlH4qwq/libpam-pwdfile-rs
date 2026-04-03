{
  config,
  lib,
  pkgs,
  ...
}:
let
  package = pkgs.callPackage ./package.nix { };
  cfg = config.libpam-pwdfile-rs;

  # Generate pwdfile content
  mkPwdfileContent =
    users: lib.concatStringsSep "\n" (lib.mapAttrsToList (name: val: "${name}:${val.secret}") users);

  # New pwdfile path
  pwdfilePath = name: "/run/libpam-pwdfile-rs/${name}";
in
{
  options.libpam-pwdfile-rs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          pwdfile = lib.mkOption {
            type = lib.types.path;
            default = /etc/pwdfile;
            visible = false;
            description = lib.mdDoc ''
              **DEPRECATED**: This option is deprecated and no longer has any effect.
              pwdfile is now automatically managed at `/run/libpam-pwdfile-rs/<name>`.
            '';
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
        services = [
          "gdm"
          "polkit-1"
        ];
        users.yourname.secret = "$y$j9T$...";
      };
    };
    description = "pwdfile instances used to auth.";
  };

  config = lib.mkIf (cfg != { }) {
    # Warn users who still use the deprecated pwdfile option
    warnings = lib.flatten (
      lib.mapAttrsToList (
        name: val:
        lib.optional (val.pwdfile != /etc/pwdfile)
          "libpam-pwdfile-rs.${name}.pwdfile is deprecated and has no effect. pwdfile is now at ${pwdfilePath name}"
      ) cfg
    );

    security.wrappers.pam_pwdfile_rs_helper = {
      source = "${package}/bin/pam_pwdfile_rs_helper";
      setuid = true;
      owner = "root";
      group = "root";
    };

    security.pam.services = lib.mkMerge (
      lib.mapAttrsToList (
        name: val:
        lib.genAttrs val.services (serviceName: {
          rules.auth.pwdfile = {
            # Run before pam_unix (sufficient: skip remaining auth rules if success)
            order = config.security.pam.services.${serviceName}.rules.auth.unix.order - 50;
            control = "sufficient";
            modulePath = "${package}/lib/security/pam_pwdfile_rs.so";
            args = [
              "pwdfile"
              (pwdfilePath name)
            ];
          };
        })
      ) cfg
    );

    # Use systemd-tmpfiles to create directory and files
    systemd.tmpfiles.settings."10-libpam-pwdfile-rs" = {
      "/run/libpam-pwdfile-rs".d = {
        mode = "0700";
        user = "root";
        group = "root";
      };
    }
    // lib.listToAttrs (
      lib.mapAttrsToList (
        name: val:
        lib.nameValuePair (pwdfilePath name) {
          f = {
            mode = "0600";
            user = "root";
            group = "root";
            argument = mkPwdfileContent val.users;
          };
        }
      ) (lib.filterAttrs (_: val: val.users != { }) cfg)
    );
  };
}
