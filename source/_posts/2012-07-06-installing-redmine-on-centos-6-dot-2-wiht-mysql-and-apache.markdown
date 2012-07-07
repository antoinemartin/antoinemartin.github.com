---
layout: post
title: "Installing Redmine on CentOS 6.2 wiht MySQL and Apache"
date: 2012-07-06 17:56
comments: true
categories: 
- Linux
- Redmine
- CentOS
- Ruby
---

I needed recently to install the excellent project management tool 
[Redmine](http://www.redmine.org/) on a [CentOS](http://www.centos.org/)
 6.2 machine. There are some tutorials on the Web ([here](http://www.redmine.org/projects/redmine/wiki/How_to_Install_Redmine_on_CentOS_%28Detailed%29)
or [here](http://luzem.dyndns.org/2011/04/14/install-redmine-in-rhel6-and-rh-based-distributions/))
but they are a little bit outdated. The following is a method that works as of
today.

<!-- More -->

## Pre-requisites

Logged as root, install the following packages:

``` sh
yum install make gcc gcc-c++ zlib-devel ruby-devel rubygems ruby-libs apr-devel apr-util-devel httpd-devel mysql-devel mysql-server automake autoconf ImageMagick ImageMagick-devel curl-devel
```

And then install the ``bundle`` ruby gem:

``` sh
gem install bundle
```

## Install Redmine

Redmine is installed with the following commmands:

``` sh
cd /var/www
wget http://rubyforge.org/frs/download.php/76255/redmine-1.4.4.tar.gz
tar zxf redmine-1.4.4.tar.gz
ln -s redmine-1.4.4 redmine
rm -f redmine-1.4.4.tar.gz
```

## Install Redmine ruby dependencies

Bundle helps us install the ruby Redmine dependencies:

``` sh
cd /var/www/redmine
bundle install --without postgresql sqlite test development
```

## Database creation

First we start MySQL:

```sh
service mysqld start
```

Then we secure it (Optional):

```sh
mysql_secure_installation 
```

We then create the redmine database and user:

```sh
$ mysql
mysql> create database redmine character set utf8;
mysql> grant all privileges on redmine.* to 'redmine'@'localhost' identified by 'my_password';
mysql> flush privileges;
mysql> quit
```

## Redmine database configuration

We copy the database configuration example and we modify it to point to our 
newly created database:

```sh
cd /var/www/redmine/config
copy database.yml.example database.yml
```

On the ``database.yml`` file, the ``production`` section should look like this:

``` yaml
production:
  adapter: mysql
  database: redmine
  host: localhost
  username: redmine
  password: my_password
  encoding: utf8

```

And then we create and populate the database with the following rake commands:

``` sh
cd /var/www/redmine
rake generate_session_store
rake db:migrate RAILS_ENV="production"
rake redmine:load_default_data RAILS_ENV="production"
```

## Outgoing email configuration (Optional)

To configure an outgoing SMTP server for sending emails, we create the 
``config/configuration.yml`` file from the sample:

``` sh
cd /var/www/redmine/config
cp configuration.yml.example configuration.yml
```

And edit it to provide our configuration :

```yaml
production:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: "smtp.mydomain.com"
      port: 25
      domain: "mydomain.com"

```


## Redmine standalone testing

At this point, Redmine can be tested in _standalone_ mode by running the 
following command:

```sh
cd /var/www/redmine/
ruby script/server webrick -e production
```

and open the ``http://localhost:3000`` addess in a browser. If you are testing
from another computer, you will need to open the port in the
``/etc/sysconfig/iptables`` file by duplicating the ssh (port 22) line and 
adapting it:

```
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3000 -j ACCEPT
```

Then apply the new configuration with the following command:

```sh
service iptables restart
```

## Passenger installation

To install [Phusion passenger](http://www.modrails.com/), we firts install its
gem:

```sh
gem install passenger
```

And then install the Apache module with the command:

```sh
passenger-install-apache2-module
```

## Apache configuration

We remove the default Apache configuration and replace it by a new one:

```sh
cd /etc/httpd
mv conf.d available
mkdir conf.d
```

In the empty new ``conf.d`` folder, we create a ``redmine.conf`` file with the
following configuration:

```
# Loading Passenger
LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-3.0.13/ext/apache2/mod_passenger.so
PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-3.0.13
PassengerRuby /usr/bin/ruby

<VirtualHost *:80>
   ServerName redmine.mycompany.com
   DocumentRoot /var/www/redmine/public
   <Directory /var/www/redmine/public>
      # This relaxes Apache security settings.
      AllowOverride all
      # MultiViews must be turned off.
      Options -MultiViews
      allow from all
   </Directory>

   ErrorLog "|/usr/sbin/rotatelogs /etc/httpd/logs/redmine-error.%Y-%m-%d.log 86400"
   CustomLog "|/usr/sbin/rotatelogs /etc/httpd/logs/redmine-access.%Y-%m-%d.log 86400" "%h %l %u %t %D \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""

</VirtualHost>

```

We then enable named based virtual hosting for our server by __uncomenting__ the
following line in the ``/etc/httpd/conf/httpd.conf`` file:

```
...
#
# Use name-based virtual hosting.
#
NameVirtualHost *:80
...
```

We give full access on the redmine folder to the ``apache`` user and test the 
configuration:

```sh
chown -R apache:root /var/www/redmine
service httpd configtest
```

At this point, the SELinux configuration needs to be modified to allow our 
apache instance to run the phusion passenger module. You can do this by putting
SELinux in permissive mode:

```sh 
setenfore Permissive
```

And letting the Permissive mode survive a reboot by modifyin the 
``/etc/selinux/config`` file from:

```
SELINUX=enforcing
```

to 

```
SELINUX=permissive
```

If you want to run redmine while enforcing, you may want to apply the method 
[described here](http://www.bangheadonwall.net/?p=343) for which you will need 
to install the ``policycoreutils-python`` package.

In any case, you will start Apache with the command:

```sh
service httpd start
```

Now you can access your Redmine installation with your browser. To access it
from all the computers in your network, you will need to open the port 80 in the
``/etc/sysconfig/iptables``. You can replace the 3000 rule by :

```
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
```

And restart iptables.

```sh
service iptables restart
```

## Start services at boot

To have MySQL and Apache started at boot, run the commands:

```sh
chkconfig --level 345 mysqld on
chkconfig --level 345 httpd on
```


## Cleaning up

A quick command to clean up all the ``devel`` stuff needed for installation:

```sh
yum remove '*-devel' make automake autoconf
```


## Tips

Don't forget that if you change your Redmine configuration, you don't have to 
restart Apache. Your can restart only Redmine with the command:

```sh
touch /var/www/redmine/tmp/restart.txt
```

If you restore data on your server from another redmine instance that runs on a
previous version, dont forget to migrate your data:

```sh
cd /var/www/redmine
rake db:migrate RAILS_ENV="production"
```