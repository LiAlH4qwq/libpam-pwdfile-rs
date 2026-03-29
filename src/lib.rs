#[macro_use]
extern crate pamsm;
use pamsm::{Pam, PamError, PamFlags, PamLibExt, PamServiceModule};
use password_hash::{PasswordHash, PasswordVerifier};
use std::{ffi::CStr, io::BufRead};
use yescrypt::Yescrypt;

macro_rules! try_or_ret {
    ($expr:expr, $err:expr) => {
        match $expr {
            Ok(val) => val,
            Err(_) => return $err,
        }
    };
    ($expr:expr) => {
        match $expr {
            Ok(exp) => exp,
            Err(e) => return e,
        }
    };
}

struct PamPwdfile;

fn get_string(pam_string: Result<Option<&CStr>, PamError>) -> Result<String, PamError> {
    match pam_string {
        Ok(Some(p)) => Ok(p.to_str().map_err(|_| PamError::AUTH_ERR)?.to_string()),
        _ => Err(PamError::AUTH_ERR),
    }
}

impl PamServiceModule for PamPwdfile {
    fn setcred(_: Pam, _: PamFlags, _: Vec<String>) -> PamError {
        PamError::SUCCESS
    }

    fn authenticate(pamh: Pam, _flags: PamFlags, args: Vec<String>) -> PamError {
        let username: String = try_or_ret!(get_string(pamh.get_cached_user()));
        let password: String = try_or_ret!(get_string(pamh.get_authtok(None)));

        let path_to_file = if let Some(index) = args.iter().position(|x| x == "pwdfile") {
            if let Some(pwdfile) = args.get(index + 1) {
                pwdfile
            } else {
                return PamError::AUTH_ERR;
            }
        } else {
            return PamError::AUTH_ERR;
        };

        let file = try_or_ret!(
            std::fs::File::open(path_to_file),
            PamError::AUTHINFO_UNAVAIL
        );

        let reader = std::io::BufReader::new(file);
        for i in reader.lines() {
            let line = try_or_ret!(i, PamError::AUTHINFO_UNAVAIL);
            let Some((user, stored_hash)) = line.split_once(':') else {
                continue;
            };
            if user.trim() != username {
                continue;
            }
            let parsed = match PasswordHash::new(stored_hash.trim()) {
                Ok(h) => h,
                Err(_) => return PamError::AUTH_ERR,
            };
            if Yescrypt.verify_password(password.as_bytes(), &parsed).is_ok() {
                return PamError::SUCCESS;
            }
        }

        PamError::AUTH_ERR
    }
}

pam_module!(PamPwdfile);
