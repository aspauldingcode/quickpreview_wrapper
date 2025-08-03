use std::env;

fn main() {
    println!("cargo:warning=Target OS: {}", env::var("CARGO_CFG_TARGET_OS").unwrap_or_else(|_| "unknown".to_string()));
    
    #[cfg(target_os = "macos")]
    {
        cc::Build::new()
            .file("macos/macos.m")
            .compile("macos");
        
        println!("cargo:rustc-link-lib=framework=Cocoa");
        println!("cargo:rustc-link-lib=framework=Quartz");
    }
    
    #[cfg(windows)]
    {
        // Let cc-rs handle MSVC detection naturally
        let mut build = cc::Build::new();
        build.file("windows/openfile_windows.c");
        
        // Enable verbose output for debugging
        if env::var("CARGO_BUILD_VERBOSE").is_ok() {
            build.flag_if_supported("-v");
        }
        
        // Trust cc-rs to find the toolchain - it should work since you added it to PATH
        build.compile("openfile_windows");
        
        // Link against Windows libraries
        println!("cargo:rustc-link-lib=user32");
        println!("cargo:rustc-link-lib=shell32");
        println!("cargo:rustc-link-lib=ole32");
    }
}
