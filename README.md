# libpam-pwdfile-rs

Rust port of [libpam-pwdfile](https://git.tiwe.de/libpam-pwdfile.git),
a PAM module that auth against pwdfile.

This is useful if you want to use a different password somewhere, eg. gdm, polkit,
which behaves like PIN of Windows.

It can also be used to set multiple passwords for users.

Passwords should be hashed by sha512sum.

Forked from: [Original Repo](https://github.com/Supernovatux/libpam-pwdfile-rs)

## NixOS Configuration

Prepare hashed passwords with.

```shell
$ echo -n "your_password" | sha512sum
```

Add it to your `flake.nix` like this.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    libpam-pwdfile-rs = {
      url = "github:lialh4qwq/libpam-pwdfile-rs/v0.2.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      libpam-pwdfile-rs,
      ...
    }:
    {
      nixosConfigurations =
        {
          nixos = nixpkgs.lib.nixosSystem {
            modules = [
              libpam-pwdfile-rs.nixosModules.libpam-pwdfile-rs
              ./configuration.nix
            ];
          };
        };
    };
}
```

Add config to your system configuration like this.

```nix
# Main configuration section.
libpam-pwdfile-rs = {
    # A pwdfile config instance, can be any name.
    pin = {
      # pwdfile location.
      pwdfile = "/etc/pin";
      # Service that uses this for auth.
      services = [ "polkit-1" ];
      # Users and their passwords.
      users = {
        # Username and `sha512sum` hashed passwords
        lialh4.secret = "9347259d6b1d86cc3a1eb2dd7b5d7a529d2e26524c16307e5f5bd9ca5b7513140f6f12f1c8066ab025d40579d9911e6c5bdbd4a17ba4bd5f6abfffb2947e2141";
      };
    };
  };
```

## Non NixOS

### Installation

#### Arch Linux

Currently broken, please use [Original Repo](https://github.com/Supernovatux/libpam-pwdfile-rs) instead.

```shell
$ cd /tmp
$ curl -LO https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/download/v0.2.1/PKGBUILD
$ makepkg -si
```

#### Other distros (Generic Installation method)

```shell
$ git clone https://github.com/lialh4qwq/libpam-pwdfile-rs
$ cd libpam-pwdfile-rs
$ cargo build --release
$ run0 cp target/release/libpam_pwdfile_rs.so /usr/lib/security/pam_pwdfile_rs.so
```

### Configuration

To use custom passwords for specific users, create a file at `/etc/pwdfile` and add the hashed passwords for each user in the format `username:passwordhash`. You can use the `sha512sum `command to generate the hash of the password you want to use. For example, to use the password `password_foo` for user `foo`, run the command:

```shell
$ echo -n "password_foo" | sha512sum
```

This will output the hash in the format `<hash> -`, where `<hash>` is the generated password hash. Copy the hash and paste it in the `/etc/pwdfile` file in the format `foo:<hash>`. Repeat this process for each user and password combination you want to set.You may provide multiple entries for a single user if you want a user to have multiple passwords.You may use this command to automate the above process `printf "password_foo" | sha512sum | awk '{print $1}' |  sed 's/.*/$ foo:&/' | sudo tee -a /etc/pwdfile`

Say you want to use custom password for two users `foo` and `bar` with the password `password_foo` and `password_bar` respectively.Then your `/etc/pwdfile` should look like below

```shell
$ sudo cat /etc/pwdfile
foo:c717e50d9dd5fb98877de7972daffa0f331e00496684f2d99642994cc777b6258df9a6397ecdf52456972e0fcf46104f4809a99d53102e6c7c70186b88263007
bar:9603f874c66bbcdac59b0f3ed6ebf510d10fcebc588e7712bfbae5eec687dfb134470ca98c74d55bed8368012706038874e108bb3ae876cdaf8206715274e442
```

Then if you want to use this password for sudo the file `/etc/pam.d/sudo` should look like this

```shell
$ cat /etc/pam.d/sudo
#%PAM-1.0
auth        sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile
auth        include     system-auth
account     include     system-auth
session     include     system-auth
```

Similarly, for other PAM services, you can prepend the line 
`auth        sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile`
to the file `/etc/pam.d/<service>`.

### Uninstallation

You may want to undo the changes to pam.d directory first

#### Arch Linux

```shell
$ sudo pacman -Rns libpam-pwdfile-rs
```

#### Other distros

```shell
$ sudo rm /usr/lib/security/pam_pwdfile_rs.so
```