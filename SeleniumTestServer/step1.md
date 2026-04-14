# Step 1 - Install Base Packages

## Ensure all packages are up to date

```
dnf update -y
```
## Install Composer

```
dnf install -y composer
```

## Install PHP 8.5 

```
dnf install -y php85 php85-php-cli php85-php-common php85-php-fpm php85-php-gd php85-php-intl php85-php-libvirt php85-php-mbstring php85-php-lz4 php85-php-pear

dnf install -y php85-php-ast php85-php-bcmath php85-php-ffi php85-php-pecl-imap php85-php-ldap php85-php-mysqlnd php85-php-opcache php85-php-pdo php85-php-pecl-csv

dnf install -y php85-php-pecl-env php85-php-pecl-lzf php85-php-pecl-mailparse php85-php-pecl-zip php85-php-process php85-php-soap php85-php-sodium php85-php-xml

dnf install -y php85-php-pecl-redis6

rm -f /usr/bin/php

ln -s /usr/bin/php85 /usr/bin/php
```

## Install The Java SKD and Runtimes

This installs the JAVA technology that Selinium relies on, over time the version may change so if it does not work you can use `dnf search openjdk` to see what versions are available. After install you can use `java -version` to verify the installation. 

```
dnf repolist

dnf -y install dnf-plugins-core

dnf config-manager --set-enabled appstream

dnf config-manager --set-enabled crb

dnf makecache

dnf -y install java-21-openjdk java-21-openjdk-headless
```

