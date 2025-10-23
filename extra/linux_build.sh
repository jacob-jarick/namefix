#!/bin/bash

# Package namefix for Linux distribution
# Creates a tar.bz2 archive with all files needed for Linux users

set -e  # Exit on any error

# Define variables

# get script directory full path

PACKAGE_NAME="namefix"
BUILD_DATE=$(date +"%Y%m%d-%H%M%S")

VERSION=$(perl ./namefix-cli.pl --version)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# get script directory parent directory
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
EXTRA_DIR="${PARENT_DIR}/extra"
BUILD_DIR="${PARENT_DIR}/builds"
TEMP_DIR="/tmp/${PACKAGE_NAME}"

CLI_PAR="namefix-cli.par"
GUI_PAR="namefix-gui.par"

ARCHIVE_PATH="${BUILD_DIR}/${PACKAGE_NAME}.${VERSION}.tar.bz2"

BUILD_DATE_FILE="${BUILD_DIR}/namefix.${VERSION}.linux.builddate.txt"

MODULES_SCRIPT="${EXTRA_DIR}/modules_linux.sh"
INSTALL_SCRIPT="${EXTRA_DIR}/install.sh"

CHANGELOG_FILE="${PARENT_DIR}/data/txt/changelog.txt"

echo "Version:          ${VERSION}"
echo "Parent directory: ${PARENT_DIR}"
echo "Build directory:  ${BUILD_DIR}"
echo "Build date file:  ${BUILD_DATE_FILE}"
echo "Archive path:     ${ARCHIVE_PATH}"
echo "Script directory: ${SCRIPT_DIR}"
echo "Extra directory:  ${EXTRA_DIR}"
echo "Modules script:   ${MODULES_SCRIPT}"
echo "Install script:   ${INSTALL_SCRIPT}"
echo "Changelog file:   ${CHANGELOG_FILE}"
echo "Temp directory:   ${TEMP_DIR}"
echo -e "\n\n"


echo "Cleaning up any previous temporary files..."
rm -rfv "${TEMP_DIR}"

echo "remove old archive and sha1sum"
rm -vf "${BUILD_DIR}"/*bz2 "${BUILD_DIR}"/*.sha1sum "${BUILD_DIR}"/*.linux.builddate.txt || echo "No old archive or sha1sum to remove"

echo "Set build date: ${BUILD_DATE}"
echo "${BUILD_DATE}" > "${BUILD_DATE_FILE}"

echo "Updating changelog"
git log | head -100 > "${CHANGELOG_FILE}"

echo "Building CLI PAR"

# Build CLI PAR
if [ -f "namefix-cli.pl" ]; then
    pp -p -v -o "${CLI_PAR}" \
        -M MP3::Tag \
        -M Time/localtime.pm \
        -M File::Spec::Functions \
        namefix-cli.pl
else
    echo "Warning: namefix-cli.pl not found, skipping CLI PAR build"
fi

echo "Building GUI PAR"
if [ -f "namefix.pl" ]; then
    pp -p -v -o "${GUI_PAR}" \
        -M Tk \
        -M Tk::JPEG \
        -M Tk::FontDialog \
        -M Tk::ColourChooser \
        -M Config::IniHash \
        -M MP3::Tag \
        -M Tk::DirTree \
        -M Tk::Balloon \
        -M Tk::NoteBook \
        -M Tk::HList \
        -M Tk::Radiobutton \
        -M Tk::Spinbox \
        -M Tk::Text \
        -M Tk::ROText \
        -M Tk::DynaTabFrame \
        -M Tk::Menu \
        -M Tk::ProgressBar \
        -M Tk::Text::SuperText \
        -M Tk::JComboBox \
        -M Tk::Widget \
        -M Tk::Wm \
        -M Tk::Event \
        -M Time/localtime.pm \
        -M File::Spec::Functions \
        namefix.pl
else
    echo "Warning: namefix.pl not found, skipping GUI PAR build"
fi

echo "Creating Linux archive ${ARCHIVE_PATH}"

# Clean up any existing temp directory
if [ -d "${TEMP_DIR}" ]; then
    echo "Removing existing temporary directory..."
    rm -rf "${TEMP_DIR}"
fi

# Create temporary directory structure
echo "Creating temporary directory structure..."
mkdir -p "${TEMP_DIR}"

# Copy PAR files (.par files)
echo "Copying PAR files (.par files)..."
cp namefix-gui.par "${TEMP_DIR}/" 2>/dev/null || echo "Warning: namefix-gui.par not found"
cp namefix-cli.par "${TEMP_DIR}/" 2>/dev/null || echo "Warning: namefix-cli.par not found"

# copy build date file
cp -v "${BUILD_DATE_FILE}" "${TEMP_DIR}/"

# Copy complete data directory
echo "Copying data directory..."
if [ -d "data" ]; then
    cp -r data "${TEMP_DIR}/"
else
    echo "Warning: data directory not found"
	exit 1
fi

# Copy complete libs directory
echo "Copying libs directory..."
if [ -d "libs" ]; then
    cp -r libs "${TEMP_DIR}/"
else
    echo "Warning: libs directory not found"
	exit 1
fi

# Copy shell scripts from extra directory
cp -v extra/install.sh "${TEMP_DIR}/"
cp -v "${MODULES_SCRIPT}" "${TEMP_DIR}/install_modules.sh"

# Set execution permissions for script files
echo "Setting execution permissions..."
chmod +x "${TEMP_DIR}"/*.par 2>/dev/null || echo "Warning: No .par files to make executable"
chmod +x "${TEMP_DIR}"/*.sh 2>/dev/null || echo "Warning: No shell scripts to make executable"

# show tree 
echo "Package directory structure:"
tree "${TEMP_DIR}"

# Create the tar.bz2 archive
echo "Creating tar.bz2 archive..."
cd /tmp
tar -cjf "${ARCHIVE_PATH}" "${PACKAGE_NAME}"
cd - > /dev/null
ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

# remove par files
rm -vf ./*.par

# Display results
echo ""
echo "Linux packages created"
echo "  Archive: ${ARCHIVE_PATH}"
echo "  Size: ${ARCHIVE_SIZE}"

# Calculate SHA1 checksum and save to file
SHA1=$(sha1sum "${ARCHIVE_PATH}" | awk '{print $1}')
echo "${SHA1}" > "${ARCHIVE_PATH}.sha1sum"
echo "  SHA1: ${SHA1}"

