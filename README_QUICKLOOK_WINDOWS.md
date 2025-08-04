# Windows QuickLook Setup

This tool provides QuickLook functionality on Windows through multiple methods:

## Option 1: QuickLook for Windows (Recommended)

Install QuickLook for Windows from the Microsoft Store or GitHub:
- **Microsoft Store**: Search for "QuickLook" 
- **GitHub**: https://github.com/QL-Win/QuickLook

Once installed, the tool will automatically detect and use QuickLook for Windows.

## Option 2: PowerToys (Alternative)

Install Microsoft PowerToys which includes a file preview feature:
- **Microsoft Store**: Search for "PowerToys"
- **GitHub**: https://github.com/microsoft/PowerToys

## Option 3: Built-in Preview Window

If neither QuickLook nor PowerToys is installed, the tool will create a basic preview window using Windows API.

## Usage

```bash
# Preview a single file
cargo run -- image.jpg

# Preview multiple files
cargo run -- image1.jpg document.pdf

# Fullscreen mode
cargo run -- -f image.png

# Help
cargo run -- --help
```

## Controls

- **ESC** or **SPACE**: Close preview
- **Close button**: Close preview window

## Supported File Types

The tool supports all file types that have registered preview handlers in Windows, including:
- Images (JPG, PNG, GIF, BMP, SVG, etc.)
- Documents (PDF, DOCX, XLSX, PPTX, etc.)
- Text files (TXT, MD, etc.)
- And many more depending on installed applications

## Troubleshooting

If files don't open in QuickLook:
1. Ensure QuickLook for Windows is installed and running
2. Check that the file type is supported
3. Try running as administrator if needed
4. The tool will fall back to the default system viewer if QuickLook fails