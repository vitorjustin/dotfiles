#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== ASDF Update Script ==="
echo

# Ask user about error handling mode
echo -e "${BLUE}Error handling mode:${NC}"
echo "  - Strict mode (exit immediately on any error)"
echo "  - Verbose mode (show all errors and continue when possible)"
echo
read -p "Do you want to enable strict mode? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    set -e  # Exit on error
    echo -e "${GREEN}Strict mode enabled - script will exit on first error${NC}"
else
    echo -e "${YELLOW}Verbose mode enabled - script will show detailed error information${NC}"
fi
echo

# Configuration
ASDF_INSTALL_PATH="/home/vitorjustin/.local/bin"
ASDF_BINARY="${ASDF_INSTALL_PATH}/asdf"
GITHUB_REPO="asdf-vm/asdf"
DOWNLOAD_DIR="/tmp/asdf-update"

# Check if asdf is installed
if [ ! -f "${ASDF_BINARY}" ]; then
    echo -e "${RED}Error:   asdf not found at ${ASDF_BINARY}${NC}"
    exit 1
fi

# Get current version
echo "Checking current asdf version..."
CURRENT_VERSION=$(asdf --version | grep -oP 'v\d+\.\d+\.\d+' | head -1)
if [ -z "${CURRENT_VERSION}" ]; then
    echo -e "${RED}Error:  Could not determine current asdf version${NC}"
    exit 1
fi
echo -e "Current version: ${GREEN}${CURRENT_VERSION}${NC}"
echo

# Get latest version from GitHub
echo "Fetching latest version from GitHub..."

# Fetch the API response
API_RESPONSE=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")

# Check if curl succeeded
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to connect to GitHub API${NC}"
    exit 1
fi

# Check for API rate limit
if echo "${API_RESPONSE}" | grep -q "API rate limit exceeded"; then
    echo -e "${RED}Error: GitHub API rate limit exceeded${NC}"
    echo "Please try again later or use authentication."
    exit 1
fi

# Extract version using multiple methods for robustness
LATEST_VERSION=$(echo "${API_RESPONSE}" | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)

# Fallback method using different tools
if [ -z "${LATEST_VERSION}" ]; then
    LATEST_VERSION=$(echo "${API_RESPONSE}" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/')
fi

# Another fallback using jq if available
if [ -z "${LATEST_VERSION}" ] && command -v jq &> /dev/null; then
    LATEST_VERSION=$(echo "${API_RESPONSE}" | jq -r '.tag_name')
fi

if [ -z "${LATEST_VERSION}" ] || [ "${LATEST_VERSION}" = "null" ]; then
    echo -e "${RED}Error:   Could not fetch latest version from GitHub${NC}"
    echo "API Response (first 500 characters):"
    echo "${API_RESPONSE}" | head -c 500
    echo
    exit 1
fi

echo -e "Latest version: ${GREEN}${LATEST_VERSION}${NC}"
echo

# Compare versions (remove 'v' prefix for comparison)
CURRENT_VER_NUM="${CURRENT_VERSION#v}"
LATEST_VER_NUM="${LATEST_VERSION#v}"

# Function to compare semantic versions
version_greater() {
    # Returns 0 (true) if $1 > $2
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

if !   version_greater "${LATEST_VER_NUM}" "${CURRENT_VER_NUM}"; then
    echo -e "${YELLOW}You already have the latest version (${CURRENT_VERSION}) installed.${NC}"
    echo "No update needed.   Exiting."
    exit 0
fi

echo -e "${GREEN}New version available!  ${NC}"
echo

# Ask user for confirmation
read -p "Do you want to update from ${CURRENT_VERSION} to ${LATEST_VERSION}? (y/n): " -n 1 -r
echo
if [[ !   $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Update cancelled by user.  Exiting.${NC}"
    exit 0
fi

echo -e "${GREEN}Proceeding with update...${NC}"
echo

# Create download directory
mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"

# Find and download the linux-amd64.tar.gz asset
echo "Downloading asdf ${LATEST_VERSION} (linux-amd64.tar. gz)..."

# Get download URL - Fixed to properly exclude .md5 files
DOWNLOAD_URL=$(echo "${API_RESPONSE}" | grep '"browser_download_url"' | grep 'linux-amd64\.tar\.gz"' | grep -v '\.md5' | head -1 | sed -E 's/.*"browser_download_url":\s*"([^"]+)".*/\1/')

# Alternative fallback using a different approach
if [ -z "${DOWNLOAD_URL}" ]; then
    DOWNLOAD_URL=$(echo "${API_RESPONSE}" | grep -oP '"browser_download_url":\s*"\K[^"]*linux-amd64\.tar\.gz(?=")' | head -1)
fi

if [ -z "${DOWNLOAD_URL}" ]; then
    echo -e "${RED}Error:  Could not find linux-amd64.tar.gz download URL${NC}"
    echo "Available assets:"
    echo "${API_RESPONSE}" | grep '"browser_download_url"' | sed -E 's/.*"browser_download_url":\s*"([^"]+)".*/\1/'
    exit 1
fi

echo "Download URL: ${DOWNLOAD_URL}"

DOWNLOAD_FILE="${DOWNLOAD_DIR}/asdf-${LATEST_VERSION}-linux-amd64.tar.gz"
curl -L -o "${DOWNLOAD_FILE}" "${DOWNLOAD_URL}"

if [ $? -ne 0 ] || [ ! -f "${DOWNLOAD_FILE}" ]; then
    echo -e "${RED}Error:   Download failed${NC}"
    exit 1
fi
echo -e "${GREEN}Download complete!${NC}"
echo

# Extract the file
echo "Extracting archive..."
tar -xzf "${DOWNLOAD_FILE}" -C "${DOWNLOAD_DIR}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error:  Extraction failed${NC}"
    exit 1
fi

# Find the extracted asdf binary
EXTRACTED_ASDF=$(find "${DOWNLOAD_DIR}" -name "asdf" -type f -executable | head -1)
if [ -z "${EXTRACTED_ASDF}" ]; then
    echo -e "${RED}Error: Could not find asdf binary in extracted files${NC}"
    echo "Contents of download directory:"
    ls -la "${DOWNLOAD_DIR}"
    exit 1
fi
echo -e "${GREEN}Extraction complete!${NC}"
echo -e "Found asdf binary at:   ${EXTRACTED_ASDF}"
echo

# Create backup with version and timestamp
BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${ASDF_INSTALL_PATH}/asdf_${CURRENT_VERSION}_${BACKUP_TIMESTAMP}.bak"

echo "Creating backup..."
cp "${ASDF_BINARY}" "${BACKUP_FILE}"

if [ $?   -ne 0 ]; then
    echo -e "${RED}Error: Backup failed${NC}"
    exit 1
fi
echo -e "${GREEN}Backup created:   ${BACKUP_FILE}${NC}"
echo

# Install new version
echo "Installing new version..."
cp "${EXTRACTED_ASDF}" "${ASDF_BINARY}"
chmod +x "${ASDF_BINARY}"

if [ $?  -ne 0 ]; then
    echo -e "${RED}Error: Installation failed${NC}"
    echo "Restoring from backup..."
    cp "${BACKUP_FILE}" "${ASDF_BINARY}"
    exit 1
fi
echo -e "${GREEN}Installation complete!${NC}"
echo

# Verify installation
echo "Verifying installation..."
NEW_VERSION=$(asdf --version 2>&1)
echo -e "${GREEN}New asdf version output:${NC}"
echo "${NEW_VERSION}"
echo

# Check if the version matches what we expected
if echo "${NEW_VERSION}" | grep -q "${LATEST_VERSION}"; then
    echo -e "${GREEN}✓ Update successful!  asdf ${LATEST_VERSION} is now installed.${NC}"
else
    echo -e "${YELLOW}Warning: Version output doesn't match expected version ${LATEST_VERSION}${NC}"
    echo -e "${YELLOW}But the binary has been updated.  Please verify manually.${NC}"
fi

# Cleanup
echo
echo "Cleaning up temporary files..."
rm -rf "${DOWNLOAD_DIR}"
echo -e "${GREEN}Cleanup complete!  ${NC}"
echo

echo "=== Update Complete ==="
echo -e "Backup location:  ${BACKUP_FILE}"
