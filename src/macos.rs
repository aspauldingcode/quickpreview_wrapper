use std::ffi::CString;
use std::os::raw::{c_char, c_int};
use std::process;

#[link(name = "quickpreview_wrapper", kind = "static")]
extern "C" {
    fn openFiles(argc: c_int, argv: *const *const c_char, fullscreen: c_int) -> c_int;
}

pub fn open_quicklook(files: &[String], fullscreen: bool) {
    let c_args: Vec<CString> = files
        .iter()
        .map(|file| CString::new(file.as_str()).unwrap())
        .collect();

    let c_arg_ptrs: Vec<*const c_char> = c_args
        .iter()
        .map(|arg| arg.as_ptr())
        .collect();

    let result = unsafe {
        openFiles(
            c_arg_ptrs.len() as c_int,
            c_arg_ptrs.as_ptr(),
            if fullscreen { 1 } else { 0 },
        )
    };

    if result != 0 {
        eprintln!("Error opening QuickLook preview");
        process::exit(1);
    }

    // Wait for the user to close QuickLook
    println!("Press Enter to exit...");
    let mut input = String::new();
    std::io::stdin().read_line(&mut input).unwrap();

    process::exit(0);
}



