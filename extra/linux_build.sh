#!/bin/bash

# Package namefix for Linux distribution
# Creates a tar.bz2 archive with all files needed for Linux users

set -e  # Exit on any error

# Define variables
PACKAGE_NAME="namefix"
ARCHIVE_NAME="${PACKAGE_NAME}.tar.bz2"
TEMP_DIR="/tmp/${PACKAGE_NAME}"
CLI_PAR="namefix-cli.par"
GUI_PAR="namefix-gui.par"
BUILD_DATE=$(date +"%Y%m%d-%H%M%S")
BUILD_DATE_FILE="builds/linux.builddate.txt"

MODULES_SCRIPT="extra/modules_linux.sh"
INSTALL_SCRIPT="extra/install.sh"

INSTALL_BZ2="$builds/{PACKAGE_NAME}.tar.bz2"

echo "Set build date: ${BUILD_DATE}"
echo ${BUILD_DATE} > ${BUILD_DATE_FILE}

echo "Cleaning up any previous temporary files..."
rm -rfv "${TEMP_DIR}"

echo "Updating changelog"
git log | head -100 > data/txt/changelog.txt

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

echo "Creating Linux package for namefix..."
echo "Package name: ${ARCHIVE_NAME}"

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
cp "${BUILD_DATE_FILE}" "${TEMP_DIR}/builddate.txt"

# Copy complete data directory
echo "Copying data directory..."
if [ -d "data" ]; then
    cp -r data "${TEMP_DIR}/"
else
    echo "Warning: data directory not found"
fi

# Copy complete libs directory
echo "Copying libs directory..."
if [ -d "libs" ]; then
    cp -r libs "${TEMP_DIR}/"
else
    echo "Warning: libs directory not found"
fi

# Copy shell scripts from extra directory
cp -v extra/install.sh "${TEMP_DIR}/"
cp -v "${MODULES_SCRIPT}" "${TEMP_DIR}/install_modules.sh"

# Set execution permissions for script files
echo "Setting execution permissions..."
chmod +x "${TEMP_DIR}"/*.pl 2>/dev/null || echo "Warning: No .pl files to make executable"
chmod +x "${TEMP_DIR}"/*.par 2>/dev/null || echo "Warning: No .par files to make executable"
chmod +x "${TEMP_DIR}"/*.sh 2>/dev/null || echo "Warning: No shell scripts to make executable"

# show tree 
echo "Package directory structure:"
tree "${TEMP_DIR}"

# Create the tar.bz2 archive
echo "Creating tar.bz2 archive..."
cd /tmp
tar -cjf "${ARCHIVE_NAME}" "${PACKAGE_NAME}"
cd - > /dev/null

# Move the archive to current directory
mv "/tmp/${ARCHIVE_NAME}" ./builds/

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

# remove par files
rm -vf *.par

# Display results
echo ""
echo "Linux packages created"
echo "  Archive: ${ARCHIVE_NAME}"
echo "  Size: $(du -h ./builds/${ARCHIVE_NAME} | cut -f1)"

# Calculate SHA1 checksum and save to file
SHA1=$(sha1sum ./builds/${ARCHIVE_NAME} | awk '{print $1}')
echo "${SHA1}" > ./builds/${ARCHIVE_NAME}.sha1
echo "  SHA1: ${SHA1}"

