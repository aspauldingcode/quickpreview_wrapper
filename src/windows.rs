use std::ffi::OsStr;
use std::iter::once;
use std::os::windows::ffi::OsStrExt;
use winapi::um::shellapi::ShellExecuteW;
use winapi::um::winuser::SW_SHOW;

pub fn open_quicklook(filename: &str, fullscreen: bool) {
    let operation: Vec<u16> = OsStr::new("open").encode_wide().chain(once(0)).collect();
    let file: Vec<u16> = OsStr::new(filename).encode_wide().chain(once(0)).collect();
    let params: Vec<u16> = if fullscreen {
        OsStr::new("/f").encode_wide().chain(once(0)).collect()
    } else {
        vec![0]
    };

    unsafe {
        ShellExecuteW(
            std::ptr::null_mut(),
            operation.as_ptr(),
            file.as_ptr(),
            params.as_ptr(),
            std::ptr::null(),
            SW_SHOW,
        );
    }
}
