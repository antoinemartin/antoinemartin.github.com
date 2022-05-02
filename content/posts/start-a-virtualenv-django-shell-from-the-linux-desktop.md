---
title: "Start a Virtualenv Django Shell From the Linux Desktop"
date: "2012-03-13"
slug: "2012/03/13/start-a-virtualenv-django-shell-from-the-linux-desktop"
Categories: ["Development", "Django"]
Tags: ["snippet", "django", "linux", "bash"]
toc:
  enable: false
---

If you are tired to fire a terminal window, `cd` to your project directory and
activate your python `virtualenv` to get to your Django project, you will find
here some tips to improve things a little bit.

<!-- more -->

This tip is divided in two parts :

1. First we create a shell startup script that _activates_ the `virtualenv`,
   bash completion and `cd` in the project directory.
2. Then we create a
   [Linux Desktop Entry](http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)
   file That spawns a console in our environment.

Here you have the startup script:

```bash
#!/bin/bash
#
# The layout of the development environment is assumed to be:
#
# <pyton virtual env>/
#   src/
#     <project name>/
#       .consolerc (this file)
#       setup.py
#       ...
#       <project name>/
#         manage.py
#         settings.py
#         ...
#

# Run the standard bash rc file
source ~/.bashrc

# Get the current source file name
current="${BASH_SOURCE[0]}"

# Retrieve the source directory
DJANGO_SOURCE_DIR="$(dirname "$(readlink -f "$current")")"

# Get the Django related directories
DJANGO_PROJECT_NAME="$(basename "$DJANGO_SOURCE_DIR")"
DJANGO_ENV_DIR=$(readlink -f "${DJANGO_SOURCE_DIR}/../../")
DJANGO_PROJECT_DIR="${DJANGO_SOURCE_DIR}/${DJANGO_PROJECT_NAME}"

# Activate the environment
source "${DJANGO_ENV_DIR}/bin/activate"
cd "$DJANGO_PROJECT_DIR"
export PATH="$PATH:$(pwd)"

# Retrieve the Django bash completion file (only once) and execute it.
# This is potentially insecure.
DJANGO_BASH_COMPLETION="${DJANGO_SOURCE_DIR}/.django_bash_completion"
if [ ! -f "$DJANGO_BASH_COMPLETION" ]; then
  curl http://code.djangoproject.com/svn/django/trunk/extras/django_bash_completion -o "$DJANGO_BASH_COMPLETION" 2>/dev/null
fi
source "$DJANGO_BASH_COMPLETION"

# Miscellaneous
alias runserver='cd $DJANGO_PROJECT_DIR;manage.py runserver 0.0.0.0:8000'
```

The comment at the beginning explains how the project directory layout is
assumed to be. That is the only assumption that makes the script. In
consequence, it is reusable _as is_ in any other project.

Here is the `.desktop` file that runs a terminal console with our script:

```ini
[Desktop Entry]
Exec=/bin/bash --rcfile .consolerc
GenericName[fr]=MyProject Django
GenericName=MyProject Django
Icon=/home/antoine/images/django-icon_0.png
MimeType=
Name[fr]=MyProject Django
Name=MyProject Django
Path=/home/antoine/src/django/my_project/src/my_project/
StartupNotify=true
Terminal=true
TerminalOptions=
Type=Application
Categories=Development
```

The command runs in a terminal because of `Terminal=true`. You can see that
apart from `Name` and `GenericName`, the only line specific to the project is

```ini
Path=/home/antoine/src/django/my_project/src/my_project/
```

It defines the project path, making it easy to reuse. The execution of our init
script is done through:

```ini
Exec=/bin/bash --rcfile .consolerc
```

The `Icon` is the familiar Django icon :

![img](/images/django-icon_0.png)

I personally put the `.desktop` file in `$HOME/Desktop`, but it also can reside
in `$HOME/.local/share/applications`. In that case, the entry will be available
in the menu. I've tested this under KDE, but it should work also with Gnome.
