+++
title = "Mirror a Git Repository Through Ssh"
date = "2012-11-15"
slug = "2012/11/15/mirror-a-git-repository-through-ssh"
Categories = ["DevOps"]
tags = ["git", "ssh", "redmine", "bash"]
[toc]
enable = false
+++

Redmine can show the timeline of a Git repository but this repository needs to
be local (see [here](http://www.redmine.org/boards/2/topics/3487)). When you
host your repository externally (on GitHub, for instance), you need to
synchronize your remote repository on your Redmine server.

The following shell script is an _All in one_ command that can be easily put in
the crontab to mirror the repository on your Redmine server :

<!-- More -->

``` sh
#!/bin/sh


if [ "run" != "$1" ]; then
  exec ssh -i "$GIT_KEY" -o "StrictHostKeyChecking no" "$@"
fi

remote=$2
local=$3

echo "Mirroring from $remote to $local"

name=$(basename "$local")

export GIT_KEY="`mktemp /tmp/git.XXXXXX`"
export GIT_SSH="$0"

cat >"$GIT_KEY" <<EOF
-----BEGIN DSA PRIVATE KEY-----
### Put here your private key ###
-----END DSA PRIVATE KEY-----
EOF

if [ -d "$local" ]; then
        git "--git-dir=$local" remote update
else
        git clone --mirror "$remote" "$local"
fi

rm -f "$GIT_KEY"

exit 0

```

You need to copy the private key in the script (line 20). You can then use the
script with the following syntax

``` sh
git-import.sh run <remote_repository>  <local_repository>
```

Notice the use of the **run** argument to distinguish between executions of the
script as a user and as the `ssh` command to be used by Git.

Here is an example:

``` sh
[antoine@dev ~]$ ./git-import.sh run git@github.com:antoinemartin/django-windows-tools.git django-windows-tools.git
Mirroring from git@github.com:antoinemartin/django-windows-tools.git to django-windows-tools.git
Cloning into bare repository 'django-windows-tools.git'...  
remote: Counting objects: 112, done.
remote: Compressing objects: 100% (88/88), done.
remote: Total 112 (delta 46), reused 78 (delta 14)
Receiving objects: 100% (112/112), 41.04 KiB, done.  
Resolving deltas: 100% (46/46), done.  
[antoine@dev ~]$  
```

The first time you run the script, it
creates the Git mirror. The following runs only syncs the mirror:

``` sh
[antoine@dev ~]$ ./git-import.sh run git@github.com:antoinemartin/django-windows-tools.git django-windows-tools.git  
Mirroring from git@github.com:antoinemartin/django-windows-tools.git to django-windows-tools.git  
Fetching origin  
[antoine@dev ~]$  
```
