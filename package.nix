{
  lib,
  pam,
  pkg-config,
  rustPlatform,
  stdenv,
  llvmPackages,
}:

rustPlatform.buildRustPackage {
  pname = "libpam-pwdfile-rs";
  version = "0.4.0";

  src = lib.cleanSource ./.;

  cargoHash = "sha256-Ss2GbE/TgASAEsO2Mg097RxI9qqXjf+KmhIOERldGwE=";

  nativeBuildInputs = [
    pkg-config
    llvmPackages.clang
  ];

  buildInputs = [
    pam
  ];

  dontCargoInstall = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 \
      target/${stdenv.hostPlatform.config}/release/libpam_pwdfile_rs.so \
      $out/lib/security/pam_pwdfile_rs.so
    install -Dm755 \
      target/${stdenv.hostPlatform.config}/release/pam_pwdfile_rs_helper \
      $out/bin/pam_pwdfile_rs_helper
    runHook postInstall
  '';

  meta = {
    description = "PAM module that auth against pwdfile";
    longDescription = ''
      Rust port of libpam-pwdfile, a PAM module that auth against pwdfile.
      This is useful if you want to use a different password somewhere, eg. gdm, polkit,
      which behaves like PIN of Windows.
      It can also be used to set multiple passwords for users.
      Passwords should be hashed with yescrypt (mkpasswd -m yescrypt).
    '';
    homepage = "https://github.com/lialh4qwq/pam-pwdfile-rs";
    changelog = "https://github.com/lialh4qwq/pam-pwdfile-rs/releases/tag/v0.4.0";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
