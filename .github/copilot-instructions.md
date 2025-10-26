# Copilot Instructions for namefix.pl

## Project Overview
`namefix.pl` is a mature Perl file renaming utility (since 2000) with dual CLI/GUI interfaces for media file organization. Features 60+ renaming operations, MP3 tag integration, EXIF handling, and cross-platform support.  
It is designed for complex batch file renaming operations, especially for media collections, and is safe for testing (CLI runs in preview mode by default).

## Architecture

- **Entry Points**:  
  - `namefix.pl` (GUI, Perl/Tk)  
  - `namefix-cli.pl` (CLI)
- **Core Logic**:  
  - `libs/fixname.pm` contains `fix()` function - main renaming engine
- **State Management**:  
  - `libs/globals.pm` (global vars), `libs/state.pm` (runtime state, see below), `libs/config.pm` (settings)
- **Modularity**:  
  - `libs/cli/` and `libs/gui/` for interface-specific code
- **Other Key Modules**:  
  - `run_namefix.pm` (main processing), `mp3.pm` (MP3 tag manipulation), `filter.pm` (file filtering), `undo.pm` (undo/redo)

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

### Building Executables

#### Windows Build
```bash
# Build Windows executables and PAR files
./extra/win_build.ps1
```
Creates:
- `namefix-gui.exe` - GUI executable (temporary, cleaned up)
- `namefix.exe` - CLI executable (temporary, cleaned up)  
- `namefix.{VERSION}-{DATE}.setup.exe` - NSIS installer (final output, includes version and date in filename if configured)
- `namefix.{VERSION}-{DATE}.setup.exe.sha1sum` - SHA1 checksum file

The installer packages data files (provided by NSI installer script), but the build script generates the executables and installer. Final output is the installer EXE and its SHA1 sum.

#### Linux Packaging
```bash
# Package for Linux distribution
./extra/linux_build.sh
```
Creates:
- `namefix-gui.par` - GUI PAR archive (temporary, cleaned up)
- `namefix-cli.par` - CLI PAR archive (temporary, cleaned up)
- `namefix.{VERSION}-{DATE}.tar.bz2` - Final distributable archive
- `namefix.{VERSION}-{DATE}.tar.bz2.sha1sum` - SHA1 checksum file

Archive contents:
- Executables: `namefix-gui.par`, `namefix-cli.par`
- Directories: `data/` (configuration and patterns), `libs/` (Perl modules)
- Scripts: `install.sh`, `install_modules.sh`
- Permissions set for executables

Final outputs are the tar.bz2 archive and its SHA1 sum file.

### Installation

#### Linux/macOS Dependencies
```bash
# Install Perl modules
sudo ./extra/install_modules.sh

# Install system-wide (creates symlinks in /usr/bin)
sudo ./extra/install.sh
```

#### Module Installation
The `extra/install-modules.sh` script installs required CPAN modules:
- Data::Dumper
- Tk (for GUI)
- Tk::JComboBox
- Tk::DynaTabFrame  
- MP3::Tag

## Usage

### Running the Application

#### From Source
```bash
# GUI version
perl namefix.pl [directory]

# CLI version (always runs in preview mode by default)
perl namefix-cli.pl --help
perl namefix-cli.pl [options] [files/directories]
```

#### CLI Help Reference
For detailed CLI options and usage, see:
- `./libs/cli/cli_help.pm` - Complete CLI help documentation
- Command line: `perl namefix-cli.pl --help`

**Note**: The CLI (`namefix-cli.pl`) always runs in preview mode by default, making it completely safe for testing operations without risk of modifying files.  
To enable file modifications, include the `--process` argument. This should only be used on files in the `temp` directory. You can copy/create any files you want in `temp` for testing. Files in `temp` should be deleted once tests are done; no files in `temp` should be expected to persist.

#### PAR Executables (Standalone)
```bash
# GUI PAR
./namefix-gui.par [directory]

# CLI PAR
./namefix-cli.par [options] [files/directories]
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

## Code Conventions

- **Perl Style**: Uses strict/warnings, follows traditional Perl conventions
- **Module Loading**: Uses `use lib` to include local libs/ directory
- **Configuration**: TSV-based config files in `~/.namefix.pl/` directory
- **Logging**: Integrated logging system via misc::plog()
- **Error Handling**: Uses Carp for stack traces and error reporting

## Important Files

### Configuration & Data
- **data/** - Default configuration files, word lists, patterns
- **~/.namefix.pl/** - User configuration directory (created on first run)

## State Management System

### Overview
namefix uses a state management system to avoid race conditions.

### Core State Functions (`state.pm`)

#### Primary Functions
- **`state::set(state)`** - Atomic state transitions with validation and automatic PREVIEW flag management
- **`state::check(state)`** - Clean state inspection interface
- **`state::get(state)`** - Direct state value retrieval  
- **`state::busy()`** - Composite check for both 'run' and 'list' states

#### Automatic Features
- **PREVIEW Flag Management**: Setting state to 'idle' automatically sets PREVIEW flag
- **State Validation**: Invalid transitions are caught and logged
- **Race Condition Prevention**: Centralized control eliminates timing issues
- **Graceful Exit Pattern**: Uses `last` instead of `return` for proper cleanup

### Key Principles
1. **Single Responsibility**: Only the function setting a state should change it
2. **Atomic Transitions**: All state changes go through `state::set()` with validation
3. **Composite Checking**: Use `state::busy()` for comprehensive busy detection
4. **Automatic Cleanup**: PREVIEW flag automatically managed on idle state
5. **Consistent Interface**: All state queries use `state::check()` or `state::get()`  
6. **Graceful Exit**: Use `last` instead of `return` to allow cleanup code to execute

### Implementation Details

#### Migration Completed
- **RUN Variables**: All `$globals::RUN` assignments → `state::set('run'/'idle')`
- **STOP Variables**: All `$globals::STOP` checks → `state::check('stop')`
- **LISTING Variables**: All `$globals::LISTING` assignments → `state::set('list'/'idle')`
- **Module Organization**: All state functions moved from `globals.pm` to dedicated `state.pm`

## Testing

#### GUI Test (Auto-Exit)
```bash
# Run GUI test that auto-exits after 5 seconds
perl namefix.pl --gui-test
```

#### Unit Tests (Regression Prevention)
```bash
# Run all unit tests with verbose output
prove -v t\
```

## Version Management
Version defined in `globals.pm` as `$version`. Build scripts automatically extract version via `--version` flag for package naming.