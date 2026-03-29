# Maintainer: LiAlH4qwq <lialh4qwq@outlook.com>
pkgname=libpam-pwdfile-rs
pkgver=0.3.0
pkgrel=1
pkgdesc="PAM module for password file authentication with yescrypt"
url="https://github.com/lialh4qwq/libpam-pwdfile-rs"
license=("MIT")
arch=("x86_64")
depends=("pam")
makedepends=("cargo" "rust")
source=("$pkgname-$pkgver.tar.gz::https://github.com/lialh4qwq/$pkgname/archive/v$pkgver.tar.gz")
sha256sums=("SKIP")

build() {
    cd "$pkgname-$pkgver"
    cargo build --release --locked
}

package() {
    cd "$pkgname-$pkgver"
    install -Dm755 "target/release/libpam_pwdfile_rs.so" \
        "$pkgdir/usr/lib/security/pam_pwdfile_rs.so"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
