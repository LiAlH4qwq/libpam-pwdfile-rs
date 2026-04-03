use std::io::{self, Read};
use std::process::ExitCode;
use uzers::{get_current_uid, get_user_by_name};
use yescrypt::{PasswordHash, PasswordVerifier, Yescrypt};
use zeroize::Zeroizing;

const EXIT_SUCCESS: u8 = 0;
const EXIT_AUTH_FAIL: u8 = 1;
const EXIT_PARAM_ERROR: u8 = 2;
const EXIT_FILE_ERROR: u8 = 3;
const MAX_PASSWORD_LEN: usize = 255;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        return ExitCode::from(EXIT_PARAM_ERROR);
    }
    let username = &args[1];
    let pwdfile_path = &args[2];

    // UID validation: non-root callers can only verify themselves
    if !validate_caller_uid(username) {
        return ExitCode::from(EXIT_PARAM_ERROR);
    }

    // Read password from stdin (null-terminated, max 255 bytes)
    let password = match read_password_from_stdin() {
        Ok(p) => p,
        Err(_) => return ExitCode::from(EXIT_PARAM_ERROR),
    };

    // Verify password
    match verify_password(username, pwdfile_path, &password) {
        Ok(true) => ExitCode::from(EXIT_SUCCESS),
        Ok(false) => ExitCode::from(EXIT_AUTH_FAIL),
        Err(true) => ExitCode::from(EXIT_FILE_ERROR),
        Err(false) => ExitCode::from(EXIT_AUTH_FAIL),
    }
}

fn validate_caller_uid(target_username: &str) -> bool {
    let caller_uid = get_current_uid();

    // root can verify any user
    if caller_uid == 0 {
        return true;
    }

    // non-root: can only verify themselves
    let Some(user) = get_user_by_name(target_username) else {
        return false;
    };

    caller_uid == user.uid()
}

fn read_password_from_stdin() -> io::Result<Zeroizing<Vec<u8>>> {
    let mut buffer = Zeroizing::new(Vec::with_capacity(MAX_PASSWORD_LEN));
    let stdin = io::stdin();
    let mut handle = stdin.lock();
    let mut byte = [0u8; 1];

    for _ in 0..MAX_PASSWORD_LEN {
        match handle.read(&mut byte)? {
            0 => break, // EOF
            _ => {
                if byte[0] == 0 {
                    break; // null terminator
                }
                buffer.push(byte[0]);
            }
        }
    }
    Ok(buffer)
}

/// Verify password
/// Returns Ok(true) for correct password, Ok(false) for wrong password
/// Returns Err(true) for file error, Err(false) for user not found or parse error
fn verify_password(username: &str, path: &str, password: &[u8]) -> Result<bool, bool> {
    let file = std::fs::File::open(path).map_err(|_| true)?;
    let reader = std::io::BufReader::new(file);

    use std::io::BufRead;
    for line in reader.lines() {
        let line = line.map_err(|_| true)?;
        let Some((user, hash)) = line.split_once(':') else {
            continue;
        };
        if user.trim() != username {
            continue;
        }

        let parsed = PasswordHash::new(hash.trim()).map_err(|_| false)?;
        return Ok(Yescrypt::default()
            .verify_password(password, &parsed)
            .is_ok());
    }
    Err(false) // user not found
}
