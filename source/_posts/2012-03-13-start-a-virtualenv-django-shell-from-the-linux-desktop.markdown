---
layout: post
title: "Start a virtualenv Django shell from the Linux Desktop"
date: 2012-03-13 07:58
comments: true
categories: 
- Tips
- Django
- Linux
- Bash
---

If you are tired to fire a terminal window, `cd` to your project directory and activate your python `virtualenv`
to get to your Django project, you will find here some tips to improve things a little bit.

<!-- more -->

This tip is divided in two parts :

1. First we create a shell startup script that _activates_ the `virtualenv`, bash completion and `cd` in the project directory.
2. Then we create a [Linux Desktop Entry](http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html) file
That spawns a console in our environment.

Here you have the startup script:

{% include_code Django startup script .consolerc lang:sh %}

The comment at the beginning explains how the project directory layout is assumed to be. That is the only assumption that makes the
script. In consequence, it is reusable _as is_ in any other project.

Here is the `.desktop` file that runs a terminal console with our script:

{% include_code Django desktop file Django.desktop lang:sh%}

The command runs in a terminal because of `Terminal=true`. You can see that apart from `Name` and `GenericName`, the only 
line specific to the project is 

```
Path=/home/antoine/src/django/my_project/src/my_project/
```

It defines the project path, making it easy to reuse. The execution of our init script is done through:

```
Exec=/bin/bash --rcfile .consolerc
```

The `Icon` is the familiar Django icon :

{% img /images/django-icon_0.png %}


I personally put the `.desktop` file in `$HOME/Desktop`, but it also can reside in `$HOME/.local/share/applications`. In that 
case, the entry will be available in the menu. I've tested this under KDE, but it should work also with Gnome.
