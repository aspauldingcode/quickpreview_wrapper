use clap::{App, Arg};
use rdev::{listen, EventType, Key};
use std::process::Command;
use std::sync::mpsc;
use std::thread;

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "macos")]
mod macos;
#[cfg(target_os = "windows")]
mod windows;

fn main() {
    let matches = App::new("Quickpreview Wrapper")
        .version("0.1.0")
        .author("Your Name")
        .about("A universal CLI tool for quickpreview")
        .arg(Arg::new("fullscreen")
            .short('f')
            .long("fullscreen")
            .takes_value(false)
            .help("Open in fullscreen mode"))
        .arg(Arg::new("files")
            .multiple_values(true)
            .required(true)
            .help("Files to preview"))
        .get_matches();

    let fullscreen = matches.is_present("fullscreen");
    let files: Vec<String> = matches.values_of("files").unwrap().map(String::from).collect();

    if files.is_empty() {
        eprintln!("Error: No file paths provided.");
        return;
    }

    let (tx, rx) = mpsc::channel();

    thread::spawn(move || {
        if let Err(error) = listen(move |event| {
            if tx.send(event).is_err() {
                return;
            }
        }) {
            eprintln!("Error: {:?}", error)
        }
    });

    let mut current_file = 0;
    open_preview(&files[current_file], fullscreen);

    for event in rx {
        match event.event_type {
            EventType::KeyPress(Key::RightArrow) => {
                current_file = (current_file + 1) % files.len();
                open_preview(&files[current_file], fullscreen);
            }
            EventType::KeyPress(Key::LeftArrow) => {
                current_file = (current_file + files.len() - 1) % files.len();
                open_preview(&files[current_file], fullscreen);
            }
            EventType::KeyPress(Key::Escape) => {
                break;
            }
            _ => {}
        }
    }
}

#[cfg(target_os = "linux")]
fn open_preview(filename: &str, fullscreen: bool) {
    linux::open_sushi(filename, fullscreen);
}

#[cfg(target_os = "macos")]
fn open_preview(filename: &str, fullscreen: bool) {
    macos::open_quicklook(filename, fullscreen);
}

#[cfg(target_os = "windows")]
fn open_preview(filename: &str, fullscreen: bool) {
    windows::open_quicklook(filename, fullscreen);
}
