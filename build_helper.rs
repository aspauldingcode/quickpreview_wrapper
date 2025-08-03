use std::env;
use std::path::PathBuf;
use std::process::Command;

/// Helper function to locate MSVC toolchain on Windows
/// This implements similar logic to cc-rs registry.rs for finding link.exe
pub fn find_msvc_toolchain() -> Option<PathBuf> {
    // First try to use vswhere.exe to find Visual Studio installations
    if let Some(vs_path) = find_vs_installation() {
        return Some(vs_path);
    }
    
    // Fallback to environment variables
    if let Ok(vcinstalldir) = env::var("VCINSTALLDIR") {
        let link_path = PathBuf::from(vcinstalldir).join("bin").join("link.exe");
        if link_path.exists() {
            return Some(link_path.parent().unwrap().to_path_buf());
        }
    }
    
    // Check if link.exe is in PATH
    if let Ok(output) = Command::new("where").arg("link.exe").output() {
        if output.status.success() {
            let path_str = String::from_utf8_lossy(&output.stdout);
            if let Some(first_line) = path_str.lines().next() {
                let link_path = PathBuf::from(first_line.trim());
                if link_path.exists() {
                    return Some(link_path.parent().unwrap().to_path_buf());
                }
            }
        }
    }
    
    None
}

/// Find Windows SDK installation
pub fn find_windows_sdk() -> Option<(PathBuf, String)> {
    // Try to find Windows SDK using registry or common locations
    let sdk_base = PathBuf::from(r"C:\Program Files (x86)\Windows Kits\10");
    
    if !sdk_base.exists() {
        return None;
    }
    
    // Find the latest SDK version
    let include_path = sdk_base.join("Include");
    if let Ok(entries) = std::fs::read_dir(&include_path) {
        let mut versions: Vec<String> = entries
            .filter_map(|entry| entry.ok())
            .filter(|entry| entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false))
            .filter_map(|entry| entry.file_name().to_str().map(|s| s.to_string()))
            .filter(|name| name.starts_with("10."))
            .collect();
        
        versions.sort();
        if let Some(latest_version) = versions.last() {
            let sdk_lib_path = sdk_base.join("Lib").join(latest_version);
            if sdk_lib_path.exists() {
                return Some((sdk_lib_path, latest_version.clone()));
            }
        }
    }
    
    None
}

/// Use vswhere.exe to find Visual Studio installation
fn find_vs_installation() -> Option<PathBuf> {
    let vswhere_path = PathBuf::from(r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe");
    
    if !vswhere_path.exists() {
        return None;
    }
    
    let output = Command::new(&vswhere_path)
        .args(&[
            "-latest",
            "-products", "*",
            "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
            "-property", "installationPath"
        ])
        .output()
        .ok()?;
    
    if !output.status.success() {
        return None;
    }
    
    let install_path = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if install_path.is_empty() {
        return None;
    }
    
    // Try to find the MSVC tools directory
    let vs_path = PathBuf::from(install_path);
    let vc_path = vs_path.join("VC");
    
    // Look for the tools version file
    let tools_version_file = vc_path.join("Auxiliary").join("Build").join("Microsoft.VCToolsVersion.default.txt");
    
    if let Ok(version) = std::fs::read_to_string(&tools_version_file) {
        let version = version.trim();
        
        // Try different host architectures
        let host_archs = ["Hostx64", "Hostx86", "Hostarm64"];
        let target_archs = ["x64", "x86", "arm64"];
        
        for host_arch in &host_archs {
            for target_arch in &target_archs {
                let tools_path = vc_path.join("Tools").join("MSVC").join(version)
                    .join("bin").join(host_arch).join(target_arch);
                
                if tools_path.join("link.exe").exists() {
                    return Some(tools_path);
                }
            }
        }
    }
    
    // Fallback: try to find any MSVC version
    let msvc_path = vc_path.join("Tools").join("MSVC");
    if let Ok(entries) = std::fs::read_dir(&msvc_path) {
        for entry in entries.flatten() {
            if entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false) {
                let host_archs = ["Hostx64", "Hostx86", "Hostarm64"];
                let target_archs = ["x64", "x86", "arm64"];
                
                for host_arch in &host_archs {
                    for target_arch in &target_archs {
                        let tools_path = entry.path().join("bin").join(host_arch).join(target_arch);
                        if tools_path.join("link.exe").exists() {
                            return Some(tools_path);
                        }
                    }
                }
            }
        }
    }
    
    None
}

/// Set up environment variables for MSVC toolchain
pub fn setup_msvc_env() {
    let mut found_toolchain = false;
    let mut found_sdk = false;
    
    // Get target architecture for proper toolchain selection
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_else(|_| "x86_64".to_string());
    println!("cargo:warning=Setting up MSVC for target architecture: {}", target_arch);
    
    // Set up MSVC toolchain
    if let Some(toolchain_path) = find_msvc_toolchain() {
        println!("cargo:warning=Found MSVC toolchain at: {}", toolchain_path.display());
        found_toolchain = true;
        
        // Add the toolchain path to the PATH environment variable for the build
        if let Ok(current_path) = env::var("PATH") {
            let new_path = format!("{};{}", toolchain_path.display(), current_path);
            env::set_var("PATH", new_path);
            println!("cargo:warning=Updated PATH with MSVC toolchain");
        }
        
        // Set additional environment variables that cc-rs might use
        if let Some(parent) = toolchain_path.parent() {
            if let Some(parent) = parent.parent() {
                if let Some(parent) = parent.parent() {
                    if let Some(parent) = parent.parent() {
                        env::set_var("VCINSTALLDIR", parent);
                        println!("cargo:warning=Set VCINSTALLDIR to: {}", parent.display());
                    }
                }
            }
        }
        
        // Set CC and CXX environment variables to help cc-rs
        let cl_exe = toolchain_path.join("cl.exe");
        if cl_exe.exists() {
            env::set_var("CC", cl_exe.to_string_lossy().to_string());
            env::set_var("CXX", cl_exe.to_string_lossy().to_string());
            println!("cargo:warning=Set CC and CXX to: {}", cl_exe.display());
        }
    }
    
    // Set up Windows SDK
    if let Some((sdk_lib_path, sdk_version)) = find_windows_sdk() {
        println!("cargo:warning=Found Windows SDK {} at: {}", sdk_version, sdk_lib_path.display());
        found_sdk = true;
        
        // Set up LIB environment variable for different architectures
        let lib_arch = match target_arch.as_str() {
            "x86_64" => "x64",
            "x86" => "x86",
            "aarch64" => "arm64",
            _ => "x64", // default fallback
        };
        
        let sdk_lib_arch_path = sdk_lib_path.join("um").join(lib_arch);
        let sdk_ucrt_path = sdk_lib_path.join("ucrt").join(lib_arch);
        
        // Also add MSVC runtime libraries
        if let Some(toolchain_path) = find_msvc_toolchain() {
            if let Some(msvc_lib_path) = find_msvc_lib_path(&toolchain_path, lib_arch) {
                if let Ok(current_lib) = env::var("LIB") {
                    let new_lib = format!("{};{};{};{}", 
                        msvc_lib_path.display(),
                        sdk_lib_arch_path.display(), 
                        sdk_ucrt_path.display(), 
                        current_lib);
                    env::set_var("LIB", new_lib);
                } else {
                    let new_lib = format!("{};{};{}", 
                        msvc_lib_path.display(),
                        sdk_lib_arch_path.display(), 
                        sdk_ucrt_path.display());
                    env::set_var("LIB", new_lib);
                }
                println!("cargo:warning=Set LIB path with MSVC runtime for {} architecture", lib_arch);
            }
        }
    }
    
    if !found_toolchain || !found_sdk {
        println!("cargo:warning=Missing components detected:");
        if !found_toolchain {
            println!("cargo:warning=- MSVC toolchain not found");
        }
        if !found_sdk {
            println!("cargo:warning=- Windows SDK not found");
        }
        
        // Try to provide more specific guidance
        check_common_issues();
    }
}

/// Find MSVC library path for the given architecture
fn find_msvc_lib_path(toolchain_path: &PathBuf, lib_arch: &str) -> Option<PathBuf> {
    // Go up from bin/HostXXX/YYY to Tools/MSVC/version/lib/arch
    if let Some(host_dir) = toolchain_path.parent() {
        if let Some(bin_dir) = host_dir.parent() {
            if let Some(version_dir) = bin_dir.parent() {
                let lib_path = version_dir.join("lib").join(lib_arch);
                if lib_path.exists() {
                    return Some(lib_path);
                }
            }
        }
    }
    None
}

/// Check for common installation issues and provide guidance
fn check_common_issues() {
    // Check if vswhere.exe exists
    let vswhere_path = PathBuf::from(r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe");
    if !vswhere_path.exists() {
        println!("cargo:warning=vswhere.exe not found. This suggests Visual Studio or Build Tools are not installed.");
        println!("cargo:warning=Please install Visual Studio Build Tools from the Microsoft website.");
        return;
    }
    
    // Check if any Visual Studio installation exists
    if let Ok(output) = Command::new(&vswhere_path)
        .args(&["-latest", "-products", "*", "-property", "installationPath"])
        .output()
    {
        if output.status.success() {
        let install_path = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !install_path.is_empty() {
                println!("cargo:warning=Found Visual Studio at: {}", install_path);
                
                // Check if C++ tools are installed
                let vc_path = PathBuf::from(install_path).join("VC");
                if !vc_path.exists() {
                    println!("cargo:warning=Visual Studio found but VC directory missing.");
                    println!("cargo:warning=Please install the 'Desktop development with C++' workload.");
                } else {
                    println!("cargo:warning=VC directory found, but MSVC tools may be missing or in unexpected location.");
                    println!("cargo:warning=Please ensure 'MSVC v143 - VS 2022 C++ x64/x86 build tools' is installed.");
                }
            }
        }
    }
    
    // Check Windows SDK
    let sdk_path = PathBuf::from(r"C:\Program Files (x86)\Windows Kits\10");
    if !sdk_path.exists() {
        println!("cargo:warning=Windows SDK not found at expected location.");
        println!("cargo:warning=Please install Windows 10/11 SDK through Visual Studio Installer.");
    } else {
        println!("cargo:warning=Windows SDK directory found but may be missing required components.");
        println!("cargo:warning=Ensure 'Windows 10/11 SDK (latest version)' is selected in Visual Studio Installer.");
    }
    
    // Suggest using Developer Command Prompt
    println!("cargo:warning=As a workaround, try running cargo build from 'Developer Command Prompt for VS 2022'");
}