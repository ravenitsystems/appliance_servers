#!/usr/bin/env bash
set -euo pipefail
# Usage:
#   ./download-selenium.sh 4.32.0
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <selenium-version>"
  echo "Example: $0 4.32.0"
  exit 1
fi
VERSION="$1"
OUTPUT_PATH="/opt/selenium/selenium-server.jar"
URL="https://github.com/SeleniumHQ/selenium/releases/latest/download/selenium-server-${VERSION}.jar"
echo "Downloading Selenium Server version: ${VERSION}"
echo "From: ${URL}"
echo "To:   ${OUTPUT_PATH}"
# Ensure output directory exists
mkdir -p /opt/selenium
# Download
wget -O "${OUTPUT_PATH}" "${URL}"
echo "Download complete."
