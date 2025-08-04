use std::ffi::{CString, CStr};
use std::os::raw::{c_char, c_int};
use std::ptr;

// External C function declaration
extern "C" {
    fn openFiles(argc: c_int, argv: *const *const c_char, fullscreen: c_int) -> c_int;
}

pub fn open_quicklook(filename: &str, fullscreen: bool) -> Result<(), Box<dyn std::error::Error>> {
    // Convert Rust string to C string
    let c_filename = CString::new(filename)?;
    let c_filename_ptr = c_filename.as_ptr();
    
    // Create array of C string pointers
    let file_paths = [c_filename_ptr];
    let file_paths_ptr = file_paths.as_ptr();
    
    // Convert bool to int for C compatibility
    let fullscreen_int = if fullscreen { 1 } else { 0 };
    
    // Call the C function
    let result = unsafe {
        openFiles(1, file_paths_ptr, fullscreen_int)
    };
    
    if result == 0 {
        Ok(())
    } else {
        Err(format!("Failed to open file: {} (error code: {})", filename, result).into())
    }
}

pub fn open_quicklook_multiple(filenames: &[&str], fullscreen: bool) -> Result<(), Box<dyn std::error::Error>> {
    if filenames.is_empty() {
        return Err("No files provided".into());
    }
    
    // Convert all Rust strings to C strings
    let c_strings: Result<Vec<CString>, _> = filenames.iter()
        .map(|&s| CString::new(s))
        .collect();
    let c_strings = c_strings?;
    
    // Create array of C string pointers
    let c_string_ptrs: Vec<*const c_char> = c_strings.iter()
        .map(|cs| cs.as_ptr())
        .collect();
    
    // Convert bool to int for C compatibility  
    let fullscreen_int = if fullscreen { 1 } else { 0 };
    
    // Call the C function
    let result = unsafe {
        openFiles(c_string_ptrs.len() as c_int, c_string_ptrs.as_ptr(), fullscreen_int)
    };
    
    if result == 0 {
        Ok(())
    } else {
        Err(format!("Failed to open files (error code: {})", result).into())
    }
}
