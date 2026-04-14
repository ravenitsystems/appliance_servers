# Install the chrome drivers so it can take screenshots

## Install Google Chrome Runtime

This step installs google chrome, you can verify the installation using `google-chrome --version`

```
tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

dnf -y install google-chrome-stable
```

## Install ChromeDriver matching the version of the runtime

It is very important that the chrome driver version matches the runtime version exactly to prevent unpredictability. The script bellow attempts to automate this, once the install is complete you can check if it all went ok by using ``

```
CHROME_VERSION=$(google-chrome --version | awk '{print $3}')

CHROME_MAJOR=$(echo "$CHROME_VERSION" | cut -d. -f1)

DRIVER_VERSION=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR}")

wget -O /tmp/chromedriver-linux64.zip "https://storage.googleapis.com/chrome-for-testing-public/${DRIVER_VERSION}/linux64/chromedriver-linux64.zip"

unzip -o /tmp/chromedriver-linux64.zip -d /opt/

ln -sf /opt/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver

ln -sf /opt/chromedriver-linux64/chromedriver /usr/bin/chromedriver

chmod +x /usr/local/bin/chromedriver
```

## Verify the runtime and the driver installed correctly

To verify the runtime and driver installed ok we need to compare versions, run the following commands and if any of them return unknown command then there has been a failure. If both commands return a value we want to compare the version number which is in the format `x.x.x.x`. There maybe more information provided but ignore everything apart from the version numbers that follow that format.

```
google-chrome --version

chromedriver --version
```
