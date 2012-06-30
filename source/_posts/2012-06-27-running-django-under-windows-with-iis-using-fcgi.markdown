---
layout: post
title: "Running Django under Windows with IIS using FastCGI"
date: 2012-06-27 14:12
comments: true
categories: 
- Django
- IIS
- Windows
- FCGI
---

Windows is probably not the best production environment for 
[Django](https://www.djangoproject.com/) but sometimes one doesn't have the
choice. In that case, a few options aleardy exist, most notably the one
developed by [helicontech](http://www.helicontech.com/) that relies on
Microsoft's [Web Platform Installer](http://www.microsoft.com/web/downloads/platform.aspx). 
This solution, which is described [here](http://www.microsoft.com/web/downloads/platform.aspx),
relies on the installation of a specific native Handler developed by
Helicontech.

This handler manages the communication between IIS and the Django application
through the [FastCGI protocol](http://www.fastcgi.com) with the help of a
little python script that bridges FastCGI to WSGI. This script is derived from
the Allan Saddi [flup package](http://trac.saddi.com/flup) that is already used
by Django in the ```manage.py runfcgi``` command. The flup package doesn't work
under Windows and Helicontech has made the necessary adaptations to make it
work with its handler.

Since its version 7, IIS does however support FastCGI natively, so the use of a
specific handler to support Django is not needed. This post describes how to
configure and run a Django application with the native FastCGI IIS handler. For
that, I have myself adapted the Helicontech FastCGI to WSGI script to make it a
[Django management command](https://gist.github.com/3004168).

<!-- more -->

## Python installation

But before that, to run Django you will need to have python on your server. If
like me for some reason it is uneasy for you to run a software installer on your
server, a good choice is to use [Portable Python](http://www.portablepython.com/). 
With it, you can install and configure your python environment on your
development or staging server and install it in your production server(s)
by just copying over the ```python``` folder. You can even have different python
environments with differents configurations on the same server. To use the
portable python installation in copied in ```d:\python``` from a command line
window, juste type:

```
set path=d:\python\app\scripts;d:\python\app;%path%
```

And then python and its commands are available from the command line:

{% img /images/django/command.png 600 %} 

Another advantage of Portable Python is that it comes already bundled with 
[The Python for Windows extensions](http://sourceforge.net/projects/pywin32/)
(a.k.a. pywin32) and Django.

## Adding FastCGI to the project

In our example, the Django project will be named ```esplayer``` and will be
installed in ```d:\sites\esplayer```. Please note that this configuration has
been tested on Windows 2008 Server R2.

Take the [fcgi.py](https://gist.github.com/3004168) file and copy it in the
``management\commands`` directory of one of your project applications so that
the ```manage.py help fcgi``` command returns you:

{% img /images/django/fcgi.png 600 %} 

## Configure the FastCGI application on IIS

The next step is to configure the FastCGI Application on IIS. FastCGI is
available whenever you have installed the CGI feature on your IIS installation.
Run the server manager and go to the IIS role and configuration. Select your
website. You should see a FastCGI Settings icon:

{% img /images/django/fastcgi_settings.png 600 %} 

Double click on it and select the _Add application_ action. Enter the following
parameters:

{% img /images/django/fcgi_configuration.png 400 %} 

* In ```Full Path```, enter the path to your python executable.
* In ```Arguments```, enter the command line for running our fcgi command, i.e. ```d:\sites\esplayer\esplayer\manage.py fcgi --pythonpath=d:\sites\esplayer --settings=esplayer.settings```.
The ``pythonpath`` and ``settings`` arguments are needed to be path independent
(more on this later).

The other arguments are optional but you should review them to enter sensible
values. The ``Monitor changes to file`` setting is particularly interesting. It
will allow you to specify the path of a file that will trigger a restart of the
application whenever it is modified. You can enter the path to the
``settings.py`` of your project. I personally prefer to specify a file that I
explicitely update via a ``touch`` command.

## Create the website and configure it to use the FastCGI application

Once we have our FastCGI application configured, we need a web site to make use
of it. For it, we create a website pointing to our Django project:

{% img /images/django/website_configuration.png 400 %} 

To make the website use our FastCGI application, we create the following
``web.config`` file in the root of our project (here
d:\sites\esplayer\esplayer):

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <clear/>
      <add name="FastCGI" path="*" verb="*" modules="FastCgiModule" scriptProcessor="D:\python\App\python.exe|d:\sites\esplayer\esplayer\manage.py fcgi --pythonpath=d:\sites\esplayer --settings=esplayer.settings" resourceType="Unspecified" requireAccess="Script" />
    </handlers>
  </system.webServer>
</configuration>
```

We first clear all the request handlers and then specify that every request
(``path="*"`` and ``verb="*"``) should be managed by the ``FastCgiModule``
module. The ``scriptProcessor`` attribute reproduces the ``Full Path`` and the
``Arguments`` of our FastCGI application separated by ``|``. It allows the
module to identify the FastCGI application to which the requests will be routed.

## Static files

With the preceding ``web.config`` configuration, all the requests are routed
to the Django application. However, we want the static files of our application
to be managed by IIS itself. To do that, we first configure Django to collect
the static files in the ``static`` subdirectory of our project. For that, we
have the following configuration in our ``settings.py`` file:

```python
SITE_ROOT = os.path.abspath(os.path.dirname(__file__))
...
STATIC_URL = '/static/'
...
STATIC_ROOT = os.path.join( SITE_ROOT, 'static')
SITE_STATIC_ROOT = os.path.join( SITE_ROOT, 'local_static')

# Additional locations of static files
STATICFILES_DIRS = (
    # Don't forget to use absolute paths, not relative paths.
    ('', SITE_STATIC_ROOT),
)
..

```

The project wide defined static files are located in the ``local_static``
directory. All the static files are collected in the ``static`` directory by
running the following command:

```
python manage.py collecstatic
```

In the ``local_static`` directory we put the following ``web.config`` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <!-- this configuration overrides the FastCGI handler to let IIS serve the static files -->
    <handlers>
	  <clear/>
      <add name="StaticFile" path="*" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
    </handlers>
  </system.webServer>
</configuration>

```

Which basically inverts the ``web.config`` file or the root of the project by
clearing all the handlers and serving all requests only as static files. When
collected, this file will go in the ``static`` directory and will instruct IIS
that all requests below the path ``/static`` should be served as static files.

## Website creation automation

The website creation that is described in the previous sections can be automated 
with the following script that must be run as an administrator:

```
%windir%\system32\inetsrv\appcmd.exe set config -section:system.webServer/fastCgi /+"[fullPath='d:\python\app\python.exe',arguments='d:\sites\esplayer\esplayer\manage.py fcgi --pythonpath=d:\sites\esplayer --settings=esplayer.settings',maxInstances='4',idleTimeout='1800',activityTimeout='30',requestTimeout='90',instanceMaxRequests='100000',protocol='NamedPipe',flushNamedPipe='False',monitorChangesTo='d:\sites\esplayer\esplayer\web.config']" /commit:apphost
%windir%\system32\inetsrv\appcmd.exe add apppool /name:esplayer
%windir%\system32\inetsrv\appcmd.exe add site /name:esplayer /bindings:http://*:80 /physicalPath:d:\sites\esplayer\esplayer
%windir%\system32\inetsrv\appcmd.exe set app "esplayer/" /applicationPool:esplayer
```

The four commands run in the script do the following actions:

- Create the FastCGI application.
- Create the site application pool.
- Create the website.
- Add the created website to the application pool.

## Testing and troubleshooting

After the configuration, the website should be available through IIS. If this
is not the case, you will probably get a ``500`` Error:

{% img /images/django/500_error.png 400 %}

The first thing to do is to check that the website is available outside of IIS
by running it with the command:

```sh
python manage.py runserver 0.0.0.0:8000
```

And accessing it on ``http://localhost:8000``. If the application works as a
standalone Django application, the most common cause of error is a
misconfiguration of either the FastCGI application or the root ``web.config``
file. You need to be sure that the The ``scriptProcessor`` attribute
of the ``web.config`` matches ``Full Path`` and the ``Arguments`` of the FastCGI
application.

To troubleshoot further, the ``fcgi.py`` command provides several settings to
be put in the ``settings.py`` file : ``FCGI_LOG`` (default
``False``), when ``True``, instructs the command to create a log file in the
path pointed by ``FCGI_LOG_PATH``. If ``FCGI_LOG_PATH`` is not
defined, the log file will be created in the project root directory. The file
name name pattern of the log file will be ``fcgi_AAMMDD_HHMMSS_XXXX.log``, in
which ``AAMMDD`` is the date, ``HHMMSS`` the time and ``XXXX`` the FastCGI
application process number. If ``DEBUG`` is set to ``True`` in the settings, the
log file will contain the Django debug logs. The ``FCGI_DEBUG`` setting (default
``False``), when set to ``True``, will output in the log file information about
the FCGI protocol transfers between IIS and the Django application.

## Easing the FastCGI configuration

It is somewhat painful to have to specify the ``pythonpath`` and ``settings``
parameters both in the FastCGI configuration and in the ``web.config`` file. To
avoid entering them each time, I have created a ``manage.py`` script in the
``scripts`` subdirectory of the project root that _auto configures_ itself.
Here is the source of the file:

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-

import os,sys
from os.path import abspath, dirname

# the base path is my parent directory
base_path = dirname(dirname(abspath(__file__)))


from django.core.handlers.modpython import handler

# Add the parent directory to the path to be able to import settings
sys.path.append(base_path)
sys.path.append(dirname(base_path))

# Now we can import our settings and setup the environment
try:
    import settings # Assumed to be in the same directory.
except ImportError:
    import sys
    sys.stderr.write("Error: Can't find the file 'settings.py' in the directory containing %r. It appears you've customized things.\nYou'll have to run django-admin.py, passing it your settings module.\n(If the file settings.py does indeed exist, it's causing an ImportError somehow.)\n" % __file__)
    sys.exit(1)
from django.core.management import setup_environ
setup_environ(settings)


from django.core.management import execute_manager

if __name__ == "__main__":
    execute_manager(settings)

```

With this script, the ``Arguments`` setting of the FastCGI application becomes
``d:\sites\esplayer\esplayer\scripts\manage.py fcgi`` and the
``scriptProcessor`` attribute in the ``web.config`` file becomes 

```
scriptProcessor="D:\python\App\python.exe|d:\sites\esplayer\esplayer\script\manage.py fcgi"
```

## What next

Once this configuration is done on a project and a server, replicating it
across multiple servers is easy as the only configuration not part of the
project is the one of the FastCGI application. Most configuration files are
ported from server to server with the source code of the project.

However, the first creation and configuration could benefit from having some
management commands dedicated to it. These would be part, along with the
[fcgi.py](https://gist.github.com/3004168) command, of a specific Django
application that could be added to any project.

Furthermore, some of you may have noted that having the website point to the
root of the Django project is not mandatory. Thus the Django project itself
could be part of the python installation itself and deployed by running a Django
management command.
