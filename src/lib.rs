#[macro_use]
extern crate pamsm;
use pamsm::{Pam, PamError, PamFlags, PamLibExt, PamServiceModule};
use std::ffi::CStr;
use std::io::Write;
use std::process::{Command, Stdio};

/// Default helper search paths (by priority)
const DEFAULT_HELPER_PATHS: &[&str] = &[
    "/run/wrappers/bin/pam_pwdfile_rs_helper", // NixOS
    "/usr/bin/pam_pwdfile_rs_helper",          // FHS standard
];

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

/// Get helper path: prefer parameter-specified path, otherwise search default paths
fn find_helper(args: &[String]) -> Option<&str> {
    // Check if helper path is specified via parameter
    for arg in args {
        if let Some(path) = arg.strip_prefix("helper=")
            && !path.is_empty()
        {
            return Some(path);
        }
    }
    // Search default paths
    DEFAULT_HELPER_PATHS
        .iter()
        .find(|&path| std::path::Path::new(path).exists())
        .copied()
}

impl PamServiceModule for PamPwdfile {
    fn setcred(_: Pam, _: PamFlags, _: Vec<String>) -> PamError {
        PamError::SUCCESS
    }

    fn authenticate(pamh: Pam, _flags: PamFlags, args: Vec<String>) -> PamError {
        let username: String = try_or_ret!(get_string(pamh.get_cached_user()));
        let password: String = try_or_ret!(get_string(pamh.get_authtok(None)));

        // Get pwdfile path
        let path_to_file = if let Some(index) = args.iter().position(|x| x == "pwdfile") {
            if let Some(pwdfile) = args.get(index + 1) {
                pwdfile
            } else {
                return PamError::AUTH_ERR;
            }
        } else {
            return PamError::AUTH_ERR;
        };

        // Get helper path
        let Some(helper_path) = find_helper(&args) else {
            return PamError::AUTHINFO_UNAVAIL;
        };

        // Spawn helper process
        let mut child = match Command::new(helper_path)
            .arg(&username)
            .arg(path_to_file)
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
        {
            Ok(c) => c,
            Err(_) => return PamError::AUTHINFO_UNAVAIL,
        };

        // Send password (null-terminated)
        if let Some(mut stdin) = child.stdin.take() {
            let mut pwd_bytes = password.into_bytes();
            pwd_bytes.push(0); // null terminator
            if stdin.write_all(&pwd_bytes).is_err() {
                let _ = child.kill();
                return PamError::AUTH_ERR;
            }
            // stdin drops here, closing the pipe
        }

        // Wait for helper to return and map exit code
        match child.wait() {
            Ok(status) => match status.code() {
                Some(0) => PamError::SUCCESS,
                Some(1) => PamError::AUTH_ERR,
                Some(3) => PamError::AUTHINFO_UNAVAIL,
                _ => PamError::AUTH_ERR,
            },
            Err(_) => PamError::AUTH_ERR,
        }
    }
}

pam_module!(PamPwdfile);
