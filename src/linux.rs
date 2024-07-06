use std::process::Command;

pub fn open_sushi(filename: &str, fullscreen: bool) {
    let mut command = Command::new("sushi");
    command.arg(filename);
    if fullscreen {
        command.arg("-f");
    }
    command.spawn().expect("Failed to start sushi");
}
