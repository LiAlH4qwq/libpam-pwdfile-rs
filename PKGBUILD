# Maintainer: Supernovatux <thulashitharan.d at gmail dot com>

pkgname=libpam-pwdfile-rs-bin
_pkgname=libpam-pwdfile-rs
pkgver=0.2.1
pkgrel=1
pkgdesc="A simple PAM module to authenticate users against a password file"
url="https://github.com/lialh4qwq/libpam-pwdfile-rs"
license=("MIT")
arch=("x86_64")
provides=("libpam-pwdfile-rs")
conflicts=("libpam-pwdfile-rs")
depends=("pam")
source=("https://github.com/lialh4qwq/$_pkgname/releases/download/v$pkgver/$_pkgname-$pkgver-$CARCH.tar.gz")
sha512sums=("a0f7ee832aa5750b35d44bb9d550cb9865d016c44f87798bfa7836721cb7c9a3bd1475cfa7bacec59d1482e37fda041be6f1611c883602dbcd0dc605f166aead")

package() {
    install -Dm755 "target/$CARCH-unknown-linux-gnu/release/libpam_pwdfile_rs.so" "$pkgdir/usr/lib/security/pam_pwdfile_rs.so"
    install -Dm444 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
