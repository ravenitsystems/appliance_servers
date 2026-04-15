# Install the selinium server and setup the service

## Install the Selinium packages

The version used in this part of the install is correct at the time of writing but it will change in the future, to check the latest version visit the github page at `https://github.com/SeleniumHQ/selenium/releases`. 

```
mkdir -p /opt/selenium

cat >/usr/bin/download-selenium <<EOL
#!/usr/bin/env bash
set -euo pipefail
# Usage:
#   ./download-selenium.sh 4.32.0
if [[ \$# -ne 1 ]]; then
  echo "Usage: \$0 <selenium-version>"
  echo "Example: \$0 4.32.0"
  exit 1
fi
VERSION="\$1"
OUTPUT_PATH="/opt/selenium/selenium-server.jar"
URL="https://github.com/SeleniumHQ/selenium/releases/download/selenium-\${VERSION}/selenium-server-\${VERSION}.zip"
echo "Downloading Selenium Server version: \${VERSION}"
echo "From: \${URL}"
echo "To:   \${OUTPUT_PATH}"
# Ensure output directory exists
mkdir -p /opt/selenium
# Download
wget -O "\${OUTPUT_PATH}" "\${URL}"
echo "Download complete."
EOL

chmod +x /usr/bin/download-selenium

download-selenium 4.32.0
```
