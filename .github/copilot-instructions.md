# Copilot Instructions for namefix.pl

## Project Overview
`namefix.pl` is a mature Perl file renaming utility (since 2000) with dual CLI/GUI interfaces for media file organization. Features 60+ renaming operations, MP3 tag integration, EXIF handling, and cross-platform support.

## Architecture
- **Entry Points**: `namefix.pl` (GUI), `namefix-cli.pl` (CLI)
- **Core Logic**: `libs/fixname.pm` contains `fix()` function - main renaming engine
- **State Management**: `libs/globals.pm` (global vars), `libs/state.pm` (runtime state), `libs/config.pm` (settings)
- **Modularity**: Separate `libs/cli/` and `libs/gui/` subdirectories for interface-specific code

## Critical Patterns

### Module Loading Strategy
```perl
use lib "$Bin/libs/";
use lib "$Bin/libs/cli";  # or libs/gui for GUI
use globals;  # Always load first - contains version, paths
use state;    # Runtime state management
```

### Configuration System
- Settings stored in `%config::hash` with `config_init_value()` pattern
- Four types: `bool`, `int`, `str` with save preferences (`base`, `extended`, `no`)
- CLI flags map directly to config keys (e.g., `--clean` → `cleanup_general`)

### File Processing Flow
1. `misc::get_file_all()` - Parse file into components (dir, name, ext, type)
2. `fixname::fix()` - Apply transformations based on config flags
3. Individual `fn_*` functions handle specific operations (case, spaces, etc.)

### Testing Structure
- Tests in `t/` follow `NN_description.t` numbering pattern
- Always set `$globals::CLI = 1` in tests to avoid GUI dependencies
- Use temp directories under `temp/` for file operations
- Reset config state with custom `reset_test_config()` functions

## Build System

### PAR Packaging (Primary Distribution)
```bash
# Windows (PowerShell)
.\extra\win_build.ps1

# Linux/macOS  
./extra/linux_build.sh
```
Uses `pp` (PAR Packager) to create standalone executables. GUI requires extensive Tk module inclusion.

### Development Workflows
```bash
# Run tests
perl -Ilib t/02_fixname.t

# CLI development/debugging
perl namefix-cli.pl --debug=3 --clean --process /path

# GUI development
perl namefix.pl  # Launches in current directory
```

## Media-Specific Features

### MP3 Integration
- Uses `MP3::Tag` for ID3 manipulation
- Audio file detection via `misc::check_audio_file()`
- Tag operations in `mp3.pm` module

### EXIF Handling
- `jpegexif.pm` provides metadata removal
- GUI has dedicated EXIF tab for batch operations
- CLI uses `--exif-rm` flag

### Block Renaming (GUI Only)
Unique feature in `libs/gui/blockrename.pm` - visual bulk renaming with source/destination text panels.

## Development Guidelines

### Adding CLI Options
1. Add to `config.pm` with `config_init_value()`
2. Map in CLI argument parsing
3. Implement logic in relevant `fn_*` function in `fixname.pm`
4. Add test cases covering the new functionality

### GUI Integration
- GUI state synced via config system
- Tk interface components in `libs/gui/`
- Tab-based organization mirrors CLI option groups

### Cross-Platform Considerations
- Use `misc::get_home()` for user directory paths
- File operations through `misc::` utilities handle platform differences
- Build scripts separated by platform (`win_build.ps1`, `linux_build.sh`)

## Key Files for Understanding
- `libs/fixname.pm` - Core renaming logic, all `fn_*` functions
- `libs/config.pm` - Complete option definitions and defaults  
- `libs/misc.pm` - Utility functions for file operations, path handling
- `t/02_fixname.t` - Comprehensive test examples for core functions
- `data/defaults/` - Default configuration files (killwords, patterns)

## Version Management
Version defined in `globals.pm` as `$version`. Build scripts automatically extract version via `--version` flag for package naming.