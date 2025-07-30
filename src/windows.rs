use std::ffi::OsStr;
use std::iter::once;
use std::os::windows::ffi::{OsStrExt, OsStringExt};
use std::path::Path;
use std::ptr;

use winapi::shared::minwindef::{DWORD, FALSE};
use winapi::shared::ntdef::{HANDLE, NULL};
use winapi::shared::winerror::ERROR_PIPE_BUSY;
use winapi::um::errhandlingapi::GetLastError;
use winapi::um::fileapi::{CreateFileW, WriteFile, OPEN_EXISTING};
use winapi::um::handleapi::{CloseHandle, INVALID_HANDLE_VALUE};
use winapi::um::processthreadsapi::{GetCurrentProcess, OpenProcessToken};
use winapi::um::security::SECURITY_ATTRIBUTES;
use winapi::um::securitybaseapi::{ConvertSidToStringSidW, GetTokenInformation};
use winapi::um::winbase::LocalFree;
use winapi::um::winnt::{GENERIC_WRITE, PROCESS_QUERY_INFORMATION, TOKEN_QUERY, TOKEN_USER};
use winapi::um::winuser::SW_SHOW;

pub fn open_quicklook(filename: &str, _fullscreen: bool) {
    // Get absolute path
    let abs_path = Path::new(filename).canonicalize().ok()?.to_str()?.to_string();

    // Get current user's token
    let mut token_handle: HANDLE = NULL;
    unsafe {
        if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token_handle) == 0 {
            return;
        }
    }
    let mut token_user_size: DWORD = 0;
    unsafe {
        GetTokenInformation(token_handle, TOKEN_USER, ptr::null_mut(), 0, &mut token_user_size);
    }
    let mut token_user_buf: Vec<u8> = vec![0; token_user_size as usize];
    unsafe {
        if GetTokenInformation(token_handle, TOKEN_USER, token_user_buf.as_mut_ptr() as *mut _, token_user_size, &mut token_user_size) == 0 {
            CloseHandle(token_handle);
            return;
        }
        CloseHandle(token_handle);
    }

    // Get SID from TOKEN_USER
    let token_user = unsafe { &*(token_user_buf.as_ptr() as *const TOKEN_USER) };
    let mut sid_str_ptr: *mut u16 = ptr::null_mut();
    unsafe {
        if ConvertSidToStringSidW(token_user.User.Sid, &mut sid_str_ptr) == FALSE {
            return;
        }
    }
    let sid = unsafe {
        let len = (0..).take_while(|&i| *sid_str_ptr.offset(i) != 0).count();
        let slice = std::slice::from_raw_parts(sid_str_ptr, len);
        let os_str = std::ffi::OsString::from_wide(slice);
        os_str.to_string_lossy().into_owned()
    };
    unsafe { LocalFree(sid_str_ptr as *mut _); }

    // Construct pipe name
    let pipe_name = format!("\\\\.\\pipe\\QuickLook.App.Pipe.{}", sid);
    let pipe_name_wide: Vec<u16> = OsStr::new(&pipe_name).encode_wide().chain(once(0)).collect();

    // Create security attributes
    let mut sa = SECURITY_ATTRIBUTES {
        nLength: std::mem::size_of::<SECURITY_ATTRIBUTES>() as DWORD,
        lpSecurityDescriptor: ptr::null_mut(),
        bInheritHandle: FALSE,
    };

    // Open the named pipe
    let pipe_handle = unsafe {
        CreateFileW(
            pipe_name_wide.as_ptr(),
            GENERIC_WRITE,
            0,
            &mut sa,
            OPEN_EXISTING,
            0,
            NULL,
        )
    };
    if pipe_handle == INVALID_HANDLE_VALUE {
        return;
    }

    // Prepare message
    let message = format!("QuickLook.App.PipeMessages.Toggle|{}\\r\\n", abs_path);
    let mut written: DWORD = 0;

    // Write to pipe
    unsafe {
        WriteFile(
            pipe_handle,
            message.as_ptr() as *const _,
            message.len() as DWORD,
            &mut written,
            ptr::null_mut(),
        );
    }

    unsafe { CloseHandle(pipe_handle); }
}
