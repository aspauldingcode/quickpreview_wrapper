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
        let tools_path = vc_path.join("Tools").join("MSVC").join(version).join("bin").join("Hostx64").join("x64");
        
        if tools_path.join("link.exe").exists() {
            return Some(tools_path);
        }
    }
    
    // Fallback: try to find any MSVC version
    let msvc_path = vc_path.join("Tools").join("MSVC");
    if let Ok(entries) = std::fs::read_dir(&msvc_path) {
        for entry in entries.flatten() {
            if entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false) {
                let tools_path = entry.path().join("bin").join("Hostx64").join("x64");
                if tools_path.join("link.exe").exists() {
                    return Some(tools_path);
                }
            }
        }
    }
    
    None
}

/// Set up environment variables for MSVC toolchain
pub fn setup_msvc_env() {
    if let Some(toolchain_path) = find_msvc_toolchain() {
        println!("cargo:warning=Found MSVC toolchain at: {}", toolchain_path.display());
        
        // Add the toolchain path to the PATH environment variable for the build
        if let Ok(current_path) = env::var("PATH") {
            let new_path = format!("{};{}", toolchain_path.display(), current_path);
            env::set_var("PATH", new_path);
        }
        
        // Set additional environment variables that cc-rs might use
        if let Some(parent) = toolchain_path.parent() {
            if let Some(parent) = parent.parent() {
                if let Some(parent) = parent.parent() {
                    env::set_var("VCINSTALLDIR", parent);
                }
            }
        }
    } else {
        println!("cargo:warning=Could not find MSVC toolchain. Make sure Visual Studio Build Tools are installed.");
        println!("cargo:warning=You can install them from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022");
        
        // Try to provide more specific guidance
        check_common_issues();
    }
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
            let install_path = String::from_utf8_lossy(&output.stdout).trim();
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
    
    // Suggest using Developer Command Prompt
    println!("cargo:warning=As a workaround, try running cargo build from 'Developer Command Prompt for VS 2022'");
}