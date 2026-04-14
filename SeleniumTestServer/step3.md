# Install the selinium server and setup the service

## Install the Selinium packages

The version used in this part of the install is correct at the time of writing but it will change in the future, to check the latest version visit the github page at `https://github.com/SeleniumHQ/selenium/releases`. 

```
cat >/usr/bin/download-selenium <<EOL
mkdir -p /opt/selenium


EOL


mkdir -p /opt/selenium

wget -O /opt/selenium/selenium-server.jar https://github.com/SeleniumHQ/selenium/releases/latest/download/selenium-server-{version}.jar
```
