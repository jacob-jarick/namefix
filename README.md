# About namefix.pl

`namefix.pl` is a **comprehensive file renaming utility** originally created and shared on IRC in **2000**, then officially published on [SourceForge](https://sourceforge.net/projects/namefix/) on **May 30, 2006**. This makes **namefix** one of the earliest and most powerful **file renaming** tools available, with over 25 years of evolution and refinement. Designed to provide an advanced and customizable solution for renaming and organizing files, particularly media collections, it supports both **command-line interface (CLI)** and **graphical user interface (GUI)** functionalities.

With over **60+ specialized renaming options**, including **batch renaming**, **regex-based renaming**, **MP3 tag integration**, **filesystem-aware processing**, and **platform independence**, `namefix.pl` has been trusted by technical users for over two decades. Its flexibility and comprehensive feature set have made it the definitive solution for complex **file organization** and **filename fixing** tasks.

One standout feature in the GUI is **block renaming**, which simplifies bulk renaming tasks. Users can copy and paste a multiline text of new filenames into a "destination" text window, while a "source" text window displays the original filenames. This feature also allows users to selectively remove files from the renaming list, providing unprecedented control over batch operations.

**namefix.pl** is the original and most comprehensive **namefix** solution available, establishing the standard for advanced **file renaming** tools since 2000. With over 25 years of continuous development and feature expansion, **namefix** has evolved into the most trusted **namefix** utility for professional **file management**, offering unmatched depth and reliability for **file name fix**ing operations across all major platforms.

---

# Installation

## Quick Start

### Linux/macOS

#### Option 1: Standalone PAR Files (Recommended - No Dependencies!)
```bash
# Download and extract namefix-linux.tar.gz
tar -zxvf namefix-linux.tar.gz
cd namefix-linux/

# Run immediately - no installation needed!
./namefix-gui.par              # GUI version
./namefix-cli.par --help       # CLI version
```

#### Option 2: From Source (Full Installation)
```bash
# Download the source
wget https://github.com/jacob-jarick/namefix/archive/refs/heads/master.zip
unzip master.zip && cd namefix-master

# Install Perl dependencies (only needed for .pl files)
sudo ./extra/install-modules.sh

# Install system-wide (optional)
sudo ./extra/install.sh

# Run from source
perl namefix.pl               # GUI
perl namefix-cli.pl --help    # CLI
```

### Windows
1. Download and run `namefix.pl_install.exe` from the releases
2. Run `namefix-gui.exe` for GUI or `namefix.exe` for command line

### Standalone (No Dependencies Required)
Pre-compiled PAR executables work on any system with basic Perl:
- `namefix-gui.par` - GUI version (all modules bundled)
- `namefix-cli.par` - CLI version (all modules bundled)

```bash
# Linux/macOS - No module installation needed!
chmod +x namefix-gui.par namefix-cli.par
./namefix-gui.par              # Launch GUI
./namefix-cli.par --help       # CLI usage
```

---

# Features

## Core Functionality
- **Batch Processing**: Handle thousands of files simultaneously
- **Dual Interface**: Full-featured GUI and comprehensive CLI
- **Cross-Platform**: Linux, macOS, Windows support
- **Safe Operations**: Preview mode by default, undo functionality
- **Media-Aware**: Special handling for MP3, video, image files

## Text Processing
- **Case Conversion**: Upper/lower case, smart capitalization
- **Space Handling**: Convert underscores, dots, normalize spacing
- **Character Cleanup**: Remove/convert international characters, nasty characters
- **Custom Replacements**: Remove/replace strings with regex support
- **Truncation**: Multiple patterns - from start (default), middle with custom insertion, or end

## Advanced Renaming
- **Enumeration**: Multiple numbering styles with zero-padding
- **Pattern Matching**: Powerful regex-based transformations  
- **Scene/Unscene**: Convert between scene naming conventions
- **Custom Word Lists**: Remove unwanted words, special casing rules
- **Digit Processing**: Remove/pad numbers, format episode numbering

## Media File Support  
- **MP3 Tag Integration**: Guess tags from filenames, manipulate ID3 data
- **Multi-Format**: JPEG, MP3, MPC, MPG, AVI, WMV, OGG, MKV, and more
- **Filesystem Awareness**: Handle case-insensitive filesystems (FAT32/NTFS)

## Power User Features
- **Block Renaming** (GUI Only): Visual bulk renaming with source/destination panels
- **Recursive Processing**: Handle entire directory trees
- **Directory Renaming**: Rename folders as well as files  
- **Custom Filters**: Process only files matching specific patterns
- **Configuration Management**: Save/load preset configurations

## Safety & Recovery
- **Preview Mode**: See changes before applying
- **Undo Functionality**: Reverse the last renaming operation
- **Overwrite Protection**: Prevent accidental file overwrites
- **Backup Integration**: Works with version control systems

---

# Usage Examples

## GUI Mode
```bash
# Launch GUI in current directory
perl namefix.pl

# Launch GUI for specific directory  
perl namefix.pl /path/to/media/files
```

## CLI Examples

### Basic Cleanup
```bash
# General cleanup (recommended starting point)
namefix-cli.pl --clean --rename /path/to/files

# Fix case and convert underscores to spaces
namefix-cli.pl --case --spaces --rename /path/to/music/

# Remove unwanted strings  
namefix-cli.pl --remove="[HDTV]" --clean --rename /path/to/videos/
```

### Advanced Operations  
```bash
# Scene naming with custom patterns
namefix-cli.pl --scene --pad-num --clean --rename /path/to/TV_Shows/

# MP3 tag manipulation
namefix-cli.pl --id3-guess --id3-art="Various Artists" --rename /path/to/music/

# Enumeration Options - Multiple styles available
namefix-cli.pl --enum --enum-style=0 --enum-zero-pad=3 --rename /path/to/Photos/     # Numbers only (001, 002, 003...)
namefix-cli.pl --enum --enum-style=1 --enum-zero-pad=2 --rename /path/to/Files/      # Insert at start (01 - filename)
namefix-cli.pl --enum --enum-style=2 --rename /path/to/Documents/                    # Insert at end (filename - 1)

# Recursive processing with multiple options
namefix-cli.pl --recr --clean --case --spaces --rename /path/to/MediaLibrary/
```

### Power User Features
```bash
# Custom regex patterns with special casing
namefix-cli.pl --regexp --remove="(19|20)\d{2}" --case-sp --rename /path/to/Movies/

# Truncate Options - Multiple patterns available  
namefix-cli.pl --trunc=50 --trunc-pat=0 --rename /path/to/Documents/           # Truncate from start (default)
namefix-cli.pl --trunc=50 --trunc-pat=1 --trunc-ins="..." --rename /path/to/   # Truncate from middle with insertion
namefix-cli.pl --trunc=50 --trunc-pat=2 --rename /path/to/Files/               # Truncate from end

# Digit Processing Options
namefix-cli.pl --rm-starting-digits --clean --rename /path/to/Files/           # Remove digits from start
namefix-cli.pl --rm-all-digits --rename /path/to/Documents/                    # Remove all digits (keep extension)
namefix-cli.pl --pad-num --clean --rename /path/to/Music/                      # Pad track numbers with hyphens
namefix-cli.pl --pad-num-w0 --rename /path/to/TV/                              # Zero-pad season/episode (2x12 → 02x12)
namefix-cli.pl --pad-nnnn-wx --rename /path/to/Shows/                          # Format episode numbers (0104 → 01x04)

# Character & Case Processing
namefix-cli.pl --int --clean --rename /path/to/International/                  # Convert international chars to English
namefix-cli.pl --rm-nc --spaces --case --rename /path/to/Downloads/            # Remove nasty characters
namefix-cli.pl --uc --rename /path/to/UPPERCASE/                               # Convert to uppercase
namefix-cli.pl --lc --clean --rename /path/to/lowercase/                       # Convert to lowercase

# Advanced Filtering & Processing
namefix-cli.pl --all-files --filt="vacation" --clean --rename /path/to/Files/  # Process all files containing "vacation"
namefix-cli.pl --filt-regexp --filt="IMG_\d+" --enum --rename /path/to/Photos/ # Regex filtering with enumeration
namefix-cli.pl --media-types="mp4|mkv|avi" --clean --rename /path/to/Videos/   # Process only specific video types
```

---

# Notable Mentions & Recognition

- [**FreeBSD FreshPorts**](https://www.freshports.org/sysutils/namefix/) - Included in FreeBSD's official ports collection
- [**FSF Directory**](https://directory.fsf.org/wiki/Namefix.pl) - Listed in the Free Software Directory  
- [**Unix.com Community**](https://community.unix.com/t/namefix-pl-4-0-default-branch/203714) - Recognized as essential tool

---

# Architecture & Technical Details

## Components
- **namefix.pl** - Main GUI application (Perl/Tk)
- **namefix-cli.pl** - Command-line interface
- **libs/** - Modular Perl libraries for core functionality
- **data/** - Configuration files, word lists, patterns

## Requirements

### Bundled Executables (Recommended)
- **Windows Installer**: No requirements - all dependencies bundled
- **PAR Files** (Linux/macOS): Basic Perl interpreter only (usually pre-installed)

### Source Installation (Development)
- **Perl 5.x** (5.14+ recommended) 
- **Tk module** (for GUI functionality)
- **MP3::Tag** (for MP3 tag manipulation)
- Additional CPAN modules listed in `extra/install-modules.sh`

**Note**: PAR (Perl Archive) files bundle ALL dependencies using `pp` (PAR Packager), making them standalone executables that require only a basic Perl interpreter.

## Block Renaming (GUI Exclusive)
The block renaming feature provides a unique visual interface for complex bulk operations:
- **Source Panel**: Display current filenames
- **Destination Panel**: Enter/paste new filenames
- **Selective Processing**: Remove files from operation
- **Visual Feedback**: See exactly what will change

---

# Development & Future Plans

## Current Status
- ✅ Stable 4.1.6 release with 60+ CLI options
- ✅ Full GUI feature parity (except block renaming)
- ✅ PAR executable distribution
- ✅ Cross-platform compatibility

## Roadmap
- ✅ **PAR File Distribution**: Completed - standalone executables now available for easier deployment
- 🔄 **Automated Testing Suite**: Build out comprehensive test units to avoid regression (previously done manually with files containing common problems addressed by features)
- 🎯 **C# Port Consideration**: Considering a rebuild in C# while maintaining that Perl is still the king of regex
- 🧪 **Extended Test Coverage**: Automate the testing process for better reliability

---

# Getting Help

## Documentation
```bash
namefix-cli.pl --help        # Complete option reference
namefix-cli.pl --about       # About information  
namefix-cli.pl --changelog   # Version history
namefix-cli.pl --todo        # Development roadmap
```

## Configuration
```bash
namefix-cli.pl --ed-config   # Edit main configuration
namefix-cli.pl --ed-spcase   # Edit special casing rules
namefix-cli.pl --ed-rmwords  # Edit word removal lists
```

## Support
- **Issues**: [GitHub Issues](https://github.com/jacob-jarick/namefix/issues)
- **Email**: [mem.namefix@gmail.com](mailto:mem.namefix@gmail.com)
- **Legacy**: [Original SourceForge page](https://sourceforge.net/projects/namefix/)
- **Blog**: [namefix.blogspot.com](http://namefix.blogspot.com)

---

# License & Credits

Released under the **GPL License**. Created by **Jacob Jarick** with contributions from the open-source community.

Special thanks to Dave 'Zoid' Kirsch whose Quake 2 skin renamer inspired the original concept.

---

# Technical Notes

## Windows Compatibility
The Windows installer (`namefix.pl_install.exe`) provides a complete installation including all dependencies. For development from source, Strawberry Perl 5.14.4.1 is recommended due to Tk module compatibility with the GUI components.

## Performance
Designed to handle large media collections efficiently, with optimizations for:
- Recursive directory processing
- Large file batch operations  
- Memory-efficient string processing
- Filesystem-aware operations