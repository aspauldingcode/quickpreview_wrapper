use std::env;

mod build_helper;

fn main() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();

    // Always set up MSVC environment on Windows, even for dependencies
    if cfg!(windows) || target_os == "windows" {
        build_helper::setup_msvc_env();
    }

    if target_os == "macos" {
        let out_dir = env::var("OUT_DIR").unwrap();

        cc::Build::new()
            .file("macos/macos.m")
            .flag("-fmodules")
            .compile("macos");

        println!("cargo:rustc-link-search=native={}", out_dir);
        println!("cargo:rustc-link-lib=dylib=macos");
        println!("cargo:rustc-link-framework=Cocoa");
        println!("cargo:rustc-link-framework=Quartz");
        println!("cargo:rerun-if-changed=macos/macos.m");
    } else if target_os == "windows" {
        // Configure cc to find MSVC toolchain properly
        let mut build = cc::Build::new();
        
        // Add Windows-specific files
        build.file("windows/openfile_windows.c");
        
        // Enable verbose output to help debug toolchain issues
        if env::var("CARGO_BUILD_VERBOSE").is_ok() {
            build.flag("/verbose");
        }
        
        // Try to explicitly set the compiler if we found the toolchain
        if let Some(toolchain_path) = build_helper::find_msvc_toolchain() {
            let cl_exe = toolchain_path.join("cl.exe");
            if cl_exe.exists() {
                build.compiler(cl_exe);
            }
        }
        
        // Compile the Windows library
        build.compile("windows_openfile");
        
        // Link Windows-specific libraries
        println!("cargo:rustc-link-lib=user32");
        println!("cargo:rustc-link-lib=shell32");
        println!("cargo:rustc-link-lib=ole32");
        
        println!("cargo:rerun-if-changed=windows/openfile_windows.c");
        println!("cargo:rerun-if-changed=windows/openfile_windows.m");
    }

    println!("cargo:warning=Target OS: {}", target_os);
}
