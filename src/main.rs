use clap::{App, Arg};
use rdev::{listen, EventType, Key};
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

    open_preview(&files, fullscreen);

    // Keep the main thread alive to allow the preview to stay open
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

    for event in rx {
        if let EventType::KeyPress(Key::Escape) = event.event_type {
            break;
        }
    }
}

#[cfg(target_os = "linux")]
fn open_preview(files: &[String], fullscreen: bool) {
    for file in files {
        linux::open_sushi(file, fullscreen);
    }
}

#[cfg(target_os = "macos")]
fn open_preview(files: &[String], fullscreen: bool) {
    macos::open_quicklook(files, fullscreen);
}

#[cfg(target_os = "windows")]
fn open_preview(files: &[String], fullscreen: bool) {
    for file in files {
        if let Err(e) = windows::open_quicklook(file, fullscreen) {
            eprintln!("Error opening QuickLook for {}: {}", file, e);
        }
    }
}
