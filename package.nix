{
  lib,
  pam,
  pkg-config,
  rustPlatform,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "libpam-pwdfile-rs";
  version = "0.2.1";

  src = lib.cleanSource ./.;

  cargoHash = "sha256-Cu9otmJL0Q5j1HxygEGOJ3ywGT+M1Zn56bYw58JVe08=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    pam
  ];

  # doCheck = false;

  dontCargoInstall = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 \
      target/${stdenv.hostPlatform.config}/release/libpam_pwdfile_rs.so \
      $out/lib/security/pam_pwdfile_rs.so
    runHook postInstall
  '';

  meta = {
    description = "PAM module that auth against pwdfile";
    longDescription = ''
      Rust port of libpam-pwdfile, a PAM module that auth against pwdfile.
      This is useful if you want to use a different password somewhere, eg. gdm, polkit,
      which behaves like PIN of Windows.
      It can also be used to set multiple passwords for users.
      Passwords should be hashed by sha512sum.
    '';
    homepage = "https://github.com/lialh4qwq/pam-pwdfile-rs";
    changelog = "https://github.com/lialh4qwq/pam-pwdfile-rs/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
