Name:           pam_pwdfile_rs
Version:        0.4.0
Release:        1%{?dist}
Summary:        PAM module that authenticates against pwdfile with yescrypt

License:        MIT
URL:            https://github.com/lialh4qwq/libpam-pwdfile-rs
Source0:        %{url}/archive/v%{version}/libpam-pwdfile-rs-%{version}.tar.gz

BuildRequires:  rust >= 1.75
BuildRequires:  cargo
BuildRequires:  clang
BuildRequires:  pam-devel

%description
Rust port of libpam-pwdfile, a PAM module that authenticates against pwdfile.
Useful for setting a different password (PIN) for gdm, polkit, sudo, etc.
Passwords should be hashed with yescrypt (mkpasswd -m yescrypt).

%prep
%autosetup -n libpam-pwdfile-rs-%{version}

%build
cargo build --release --locked

%install
# PAM module
install -Dm755 target/release/libpam_pwdfile_rs.so \
    %{buildroot}%{_libdir}/security/pam_pwdfile_rs.so

# Helper binary (SUID root)
install -Dm4755 target/release/pam_pwdfile_rs_helper \
    %{buildroot}%{_bindir}/pam_pwdfile_rs_helper

%files
%license LICENSE
%doc README.md
%attr(0755,root,root) %{_libdir}/security/pam_pwdfile_rs.so
%attr(4755,root,root) %{_bindir}/pam_pwdfile_rs_helper

%changelog
* Thu Jan 01 2026 LiAlH4qwq <lialh4qwq@outlook.com> - 0.4.0-1
- Add SUID helper for non-root PAM clients (hyprlock, etc.)
- Support helper= parameter for custom helper path
