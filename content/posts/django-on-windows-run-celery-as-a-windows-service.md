+++
title = "Django on Windows: Run Celery as a Windows Service"
date = "2012-07-04"
slug = "2012/07/04/django-on-windows-run-celery-as-a-windows-service"
Categories = ["DevOps", "Django"]
tags = ["old", "obsolete", "django", "celery", "windows"]
[toc]
enable = true
+++

In my
[previous post](/posts/2012/06/27/running-django-under-windows-with-iis-using-fcgi/),
I showed how to set up a Django project on a Windows Server to be served behind
IIS. After setting up the server, the next thing we want with a Django
application is to be able to run background and scheduled tasks, and
[Celery](http://celeryproject.org/) is the perfect tool for that.

<!-- more -->

On Windows, background processes are mostly run as Windows Services.
Fortunately,
[Python for Windows Extensions](http://sourceforge.net/projects/pywin32/) (a.k.a
pywin32) provides facilities to create a Windows Service.

I have packaged the related code for this post and the previous one in a project
called
[django-windows-tools](https://github.com/antoinemartin/django-windows-tools)
available on github and the cheese shop. To make it available for your
application, simply install it with the command:

```sh
pip install django-windows-tools
```

## Configuring your project

To run Celery for your project, you need to install Celery and choose a Broker
for passing messages between the Django application and the Celery worker
processes.

Installation of celery is easy:

```posh
> pip install django-celery
```

Then you add it to your `settings.py`:

```python
INSTALLED_APPS += (
    'djcelery',
)

import djcelery
djcelery.setup_loader()
```

You can choose among
[several message brokers](http://docs.celeryproject.org/en/latest/getting-started/brokers/index.html).
I personnaly use a [Windows port of Redis](https://github.com/MSOpenTech/Redis)
installed as a
[Windows Service](https://github.com/kcherenkov/redis-windows-service). The
advantage of Redis is that it can also be used as an in-memory database. In case
you're interested, you can find [here](/downloads/redis.zip) a binay copy of my
installation.

The configuration of Redis as Celery's broker also occurs in the `settings.py`:

```python
# Redis configuration
REDIS_PORT=6379
REDIS_HOST = "127.0.0.1"
REDIS_DB = 0
REDIS_CONNECT_RETRY = True

# Broker configuration
BROKER_HOST = "127.0.0.1"
BROKER_BACKEND="redis"
BROKER_USER = ""
BROKER_PASSWORD =""
BROKER_VHOST = "0"

# Celery Redis configuration
CELERY_SEND_EVENTS=True
CELERY_RESULT_BACKEND='redis'
CELERY_REDIS_HOST='127.0.0.1'
CELERY_REDIS_PORT=6379
CELERY_REDIS_DB = 0
CELERY_TASK_RESULT_EXPIRES = 10
CELERYBEAT_SCHEDULER="djcelery.schedulers.DatabaseScheduler"
CELERY_ALWAYS_EAGER=False
```

Finally, you add the `django_windows_tools` application to your project:

```python
INSTALLED_APPS += (
    'django_windows_tools',
)
```

After the configuration, a `python manage.py syncdb` will ensure that the
database of your project is up to date.

## Enabling the service

The installed service is going to allow us to run in the backround arbitrary
management commands related to our project.

With the application installed, on the root of your project, type the following
command:

```post
D:\sites\mydjangoapp> python winservice_install
```

![img](/images/django/winservice_install.png)

It will create two files in the root directory of your project .`service.py`
will help you install, run and remove the Windows Service. It's much like
`manage.py` for the service. `service.ini` contains the list of management
commands that will be run by the Windows Service.

## Configuring the service

A look at the `service.ini` file gives us the following:

```ini
    [services]
    # Services to be run on all machines
    run=celeryd
    clean=d:\logs\celery.log

    [BEATSERVER]
    # There should be only one machine with the celerybeat service
    run=celeryd celerybeat
    clean=d:\logs\celerybeat.pid;d:\logs\beat.log;d:\logs\celery.log

    [celeryd]
    command=celeryd
    parameters=-f d:\logs\celery.log -l info

    [celerybeat]
    command=celerybeat
    parameters=-f d:\logs\beat.log -l info --pidfile=d:\logs\celerybeat.pid

    [runserver]
    # Runs the debug server and listen on port 8000
    # This one is just an example to show that any manage command can be used
    command=runserver
    parameters=--noreload --insecure 0.0.0.0:8000

    [log]
    filename=d:\logs\service.log
    level=INFO

```

The `services` section contains :

- The list of background commands to run in the `run` directive.
- The list of files to delete when refreshed or stopped in the `clean`
  directive.

Here the `run` directive contains only one command: `celeryd`. If we look at the
corresponding section of the `ini` file, we find:

```ini
    [celeryd]
    command=celeryd
    parameters=-f d:\logs\celery.log -l info
```

`command` specifies the `manage.py` command to run and `parameters` specifies
the parameters to the command.

So here the configurations tells us that the service, when started, will run a
python process equivalent to the command line:

```posh
  D:\sites\mydjangoapp> python manage.py celeryd -f d:\logs\celery.log -l info
```

And that the `d:\logs\celery.log` will be deleted between runs.

The `log` sections defines a log file and logging level for the service process
itself:

```ini
    [log]
    filename=d:\logs\service.log
    level=INFO
```

## Installing and removing the service

You need to have administrator privileges to install the service in the Windows
Registry so that it's started each time the machine boots. You do that with the
following command:

```posh
D:\sites\mydjangoapp> python service.py --startup=auto install
```

![img](/images/django/winservice_install.png)

The `--startup=auto` parameter will allow the service to start automatically
when the server boots. You can check it has been installed:

![img](/images/django/winservice_service.png)

It can be removed with the following commands:

```posh
D:\sites\mydjangoapp> python service.py remove
```

Please ensure that the Server Manager is not running when you run this command,
because in that case a complete removal of the service will need a server
restart.

## Starting and stopping the service

The service can be manually started and stopped with the following commands:

```posh
D:\sites\mydjangoapp> python service.py start
D:\sites\mydjangoapp> python service.py stop
```

If everything went fine, the python processes should be there:

![img](/images/django/winservice_process.png)

Along with the log files :

![img](/images/django/winservice_logs.png)

## Running the Beat service

If you deploy your Django project on several servers, you probably want to have
Celery worker processes on each deployed machine but only one unique Beat
process for executing scheduled tasks. You can customize the `services` section
of the `service.ini` configuration file on that specific machine, but this is
incovenient if you are sharing files between machines, for instance.

The service provides the ability to have several `services` sections in the same
configuration file for different host servers. The Windows Service will try to
find the section which name matches the name of the current server and will
fallback to the `services` section if it does not find it. This allows you to
have a different behaviour for the service on different machines. In the
preceding configuration, you have one section, named `BEATSERVER` :

```ini
    [BEATSERVER]
    # There should be only one machine with the celerybeat service
    run=celeryd celerybeat
    clean=d:\logs\celerybeat.pid;d:\logs\beat.log;d:\logs\celery.log
```

which adds the `celerybeat` command to the `celeryd` command. With this
configuration file, the service run on a machine named `BEATSERVER` will run the
Celery beat service.

The `winservice_install` facility provides a convenient option for choosing the
current machine as the _Beat_ machine. Let's try that :

![img](/images/django/winservice_beat.png)

The new `service.py` file will contain a section with the name of the current
machine:

```ini
[WS2008R2X64]
# There should be only one machine with the celerybeat service
run=celeryd celerybeat
clean=d:\logs\celerybeat.pid;d:\logs\beat.log;d:\logs\celery.log
```

Now, when run, the service will start a new python process:

![img](/images/django/winservice_process_beat.png)

And new log files for the beat service will be present:

![img](/images/django/winservice_log_beat.png)

## Changes to the configuration

The Windows Service monitor changes to the `service.ini` configuration file. In
case it is modified, the service does the following:

- Stop the background processes.
- Reread the configuration file.
- Start the background processes.

You may have seen in the `service.ini` file the `runserver` section:

```ini
    [runserver]
    # Runs the debug server and listen on port 8000
    # This one is just an example to show that any manage command can be used
    command=runserver
    parameters=--noreload --insecure 0.0.0.0:8000
```

It allows running the runserver command in a separate process. I you edit the
`service.ini` file and add `runserver` to the `run` directive:

```ini
[WS2008R2X64]
# There should be only one machine with the celerybeat service
run=celeryd celerybeat runserver
...
```

As soon as you save the file, you can make your browser point to
`http://localhost:8000` and will obtain:

![img](/images/django/winservice_runserver.png)

## Running arbitrary commands

As shown in the preceding section, virtually any Django management command can
be run by the service at startup or each time the `service.ini` file is
modified. You could imagine having a section:

```ini
[collectstatic]
command=collectstatic
parameters=--noinput
```
