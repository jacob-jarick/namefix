#!/bin/bash

# package_linux_files.sh - Package namefix for Linux distribution
# Creates a tar.gz archive with all files needed for Linux users

set -e  # Exit on any error

# Define variables
PACKAGE_NAME="namefix-linux"
ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"
TEMP_DIR="/tmp/${PACKAGE_NAME}"

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

# Copy Perl scripts (.pl files)
echo "Copying Perl scripts (.pl files)..."
cp -v namefix.pl "${TEMP_DIR}/" 2>/dev/null || echo "Warning: namefix.pl not found"
cp -v namefix-cli.pl "${TEMP_DIR}/" 2>/dev/null || echo "Warning: namefix-cli.pl not found"

# Copy PAR files (.par files)
echo "Copying PAR files (.par files)..."
cp -v namefix-gui.par "${TEMP_DIR}/" 2>/dev/null || echo "Warning: namefix-gui.par not found"
cp -v namefix-cli.par "${TEMP_DIR}/" 2>/dev/null || echo "Warning: namefix-cli.par not found"

# Copy complete data directory
echo "Copying data directory..."
if [ -d "data" ]; then
    cp -rv data "${TEMP_DIR}/"
else
    echo "Warning: data directory not found"
fi

# Copy complete libs directory
echo "Copying libs directory..."
if [ -d "libs" ]; then
    cp -rv libs "${TEMP_DIR}/"
else
    echo "Warning: libs directory not found"
fi

# Copy shell scripts from extra directory
echo "Copying shell scripts from extra directory..."
if [ -d "extra" ]; then
    mkdir -p "${TEMP_DIR}/extra"
    cp -v extra/*.sh "${TEMP_DIR}/extra/" 2>/dev/null || echo "Warning: No shell scripts found in extra/"
else
    echo "Warning: extra directory not found"
fi

# Set execution permissions for script files
echo "Setting execution permissions..."
chmod +x "${TEMP_DIR}"/*.pl 2>/dev/null || echo "Warning: No .pl files to make executable"
chmod +x "${TEMP_DIR}"/*.par 2>/dev/null || echo "Warning: No .par files to make executable"
chmod +x "${TEMP_DIR}"/extra/*.sh 2>/dev/null || echo "Warning: No shell scripts to make executable"

# Create the tar.gz archive
echo "Creating tar.gz archive..."
cd /tmp
tar -czf "${ARCHIVE_NAME}" "${PACKAGE_NAME}"
cd - > /dev/null

# Move the archive to current directory
mv "/tmp/${ARCHIVE_NAME}" ./

# Clean up temporary directory
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

# Display results
echo ""
echo "✓ Linux package created successfully!"
echo "  Archive: ${ARCHIVE_NAME}"
echo "  Size: $(du -h "${ARCHIVE_NAME}" | cut -f1)"
echo ""
echo "Contents summary:"
tar -tzf "${ARCHIVE_NAME}" | head -20
if [ $(tar -tzf "${ARCHIVE_NAME}" | wc -l) -gt 20 ]; then
    echo "... and $(( $(tar -tzf "${ARCHIVE_NAME}" | wc -l) - 20 )) more files"
fi
echo ""
echo "To test the package:"
echo "  tar -tzf ${ARCHIVE_NAME} | grep -E '\.(pl|par|sh)$'"
echo ""
echo "Package ready for distribution to Linux users!"