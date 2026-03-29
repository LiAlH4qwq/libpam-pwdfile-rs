{
  lib,
  pam,
  pkg-config,
  rustPlatform,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "libpam-pwdfile-rs";
  version = "0.3.0";

  src = lib.cleanSource ./.;

  cargoHash = "sha256-XsIhulZHnZZC5XHtT4xDkjYg4H5VKsBsQVTOE7wgkyo=";

  nativeBuildInputs = [
    pkg-config
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
    changelog = "https://github.com/lialh4qwq/pam-pwdfile-rs/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
