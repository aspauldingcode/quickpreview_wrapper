use std::env;

fn main() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();

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
    }

    println!("cargo:warning=Target OS: {}", target_os);
}
