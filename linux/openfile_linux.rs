use rdev::{listen, Event, EventType, Key};
use std::env;
use std::process::Command;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} [-f] filename1 [filename2 ...]", args[0]);
        return;
    }

    let mut fullscreen = false;
    let mut files: Vec<String> = Vec::new();

    for arg in &args[1..] {
        if arg == "-f" {
            fullscreen = true;
        } else {
            files.push(arg.clone());
        }
    }

    if files.is_empty() {
        eprintln!("Error: No files specified.");
        return;
    }

    let mut current_file = 0;
    open_sushi(&files[current_file], fullscreen);

    if let Err(error) = listen(move |event| {
        handle_event(event, &mut current_file, &files, fullscreen)
    }) {
        eprintln!("Error: {:?}", error)
    }
}

fn open_sushi(filename: &str, fullscreen: bool) {
    let mut command = Command::new("sushi");
    command.arg(filename);
    if fullscreen {
        command.arg("-f");
    }
    command.spawn().expect("Failed to start sushi");
}

fn handle_event(event: Event, current_file: &mut usize, files: &[String], fullscreen: bool) {
    match event.event_type {
        EventType::KeyPress(Key::RightArrow) | EventType::KeyPress(Key::DownArrow) => {
            println!("Right/Down key pressed");
            *current_file = (*current_file + 1) % files.len();
            open_sushi(&files[*current_file], fullscreen);
        }
        EventType::KeyPress(Key::LeftArrow) | EventType::KeyPress(Key::UpArrow) => {
            println!("Left/Up key pressed");
            *current_file = (*current_file + files.len() - 1) % files.len();
            open_sushi(&files[*current_file], fullscreen);
        }
        EventType::KeyPress(Key::KeyQ) => {
            println!("Quit key pressed");
            std::process::exit(0);
        }
        _ => {}
    }
}
