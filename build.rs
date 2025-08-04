use std::env;

fn main() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
    
    // Build the C wrapper with platform-specific implementations
    let mut build = cc::Build::new();
    
    // Common C configuration
    build
        .file("main.c")
        .file("openfile.c")
        .include(".");

    // Platform-specific configurations and files
    match target_os.as_str() {
        "macos" => {
            println!("cargo:warning=Building for macOS");
            build
                .file("macos/macos.m");
            
            // Link frameworks properly
            println!("cargo:rustc-link-lib=framework=QuickLook");
            println!("cargo:rustc-link-lib=framework=Foundation");
            println!("cargo:rustc-link-lib=framework=CoreFoundation");
            println!("cargo:rustc-link-lib=framework=AppKit");
            println!("cargo:rustc-link-lib=framework=Quartz");
            
            println!("cargo:rerun-if-changed=macos/macos.m");
        },
        "linux" => {
            println!("cargo:warning=Building for Linux");
            // Linux implementation would go here
            // For now, we'll use a placeholder
        },
        "windows" => {
            println!("cargo:warning=Building for Windows with MSVC");
            build
                .file("windows/openfile_windows.c")
                .define("_WIN32", None);
            
            // Link Windows libraries
            println!("cargo:rustc-link-lib=shell32");
            println!("cargo:rustc-link-lib=user32");
            println!("cargo:rustc-link-lib=kernel32");
            
            println!("cargo:rerun-if-changed=windows/openfile_windows.c");
        },
        _ => {
            println!("cargo:warning=Unknown target OS: {}", target_os);
        }
    }

    // Set compiler flags based on target
    if target_os == "windows" {
        // MSVC-specific flags
        build.flag_if_supported("/std:c11");
        // Enable Unicode support
        build.define("UNICODE", None);
        build.define("_UNICODE", None);
    } else {
        // GCC/Clang flags
        build.flag_if_supported("-std=c11");
    }

    build.compile("quickpreview_wrapper");

    // Rebuild triggers
    println!("cargo:rerun-if-changed=main.c");
    println!("cargo:rerun-if-changed=openfile.c");
    println!("cargo:rerun-if-changed=openfile.h");
    println!("cargo:rerun-if-changed=build.rs");
}
