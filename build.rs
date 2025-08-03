use std::env;

mod build_helper;

fn main() {
    // Set up MSVC environment early for Windows builds (including ARM64)
    // This must happen before any dependencies compile
    #[cfg(windows)]
    {
        println!("cargo:warning=Setting up MSVC environment for Windows build");
        build_helper::setup_msvc_env();
        
        // Also set environment variables that will be inherited by dependency builds
        if let Ok(path) = std::env::var("PATH") {
            println!("cargo:rustc-env=PATH={}", path);
        }
        if let Ok(lib) = std::env::var("LIB") {
            println!("cargo:rustc-env=LIB={}", lib);
        }
        if let Ok(vcinstalldir) = std::env::var("VCINSTALLDIR") {
            println!("cargo:rustc-env=VCINSTALLDIR={}", vcinstalldir);
        }
        if let Ok(cc) = std::env::var("CC") {
            println!("cargo:rustc-env=CC={}", cc);
        }
        if let Ok(cxx) = std::env::var("CXX") {
            println!("cargo:rustc-env=CXX={}", cxx);
        }
    }

    // Build the C++ wrapper
    let mut build = cc::Build::new();
    
    build
        .cpp(true)
        .file("src/quickpreview_wrapper.cpp")
        .include("src")
        .flag_if_supported("-std=c++17");

    // Platform-specific configurations
    #[cfg(target_os = "macos")]
    {
        build
            .flag("-framework")
            .flag("QuickLook")
            .flag("-framework")
            .flag("Foundation")
            .flag("-framework")
            .flag("CoreFoundation")
            .flag("-framework")
            .flag("AppKit");
    }

    #[cfg(target_os = "windows")]
    {
        // Windows-specific flags can be added here if needed
        println!("cargo:warning=Compiling for Windows");
    }

    #[cfg(target_os = "linux")]
    {
        // Linux-specific configurations can be added here
        println!("cargo:warning=Compiling for Linux");
    }

    build.compile("quickpreview_wrapper");

    println!("cargo:rerun-if-changed=src/quickpreview_wrapper.cpp");
    println!("cargo:rerun-if-changed=src/quickpreview_wrapper.h");
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=build_helper.rs");
}
